unit FxRecord.Monitor;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  FxRecord.Config,
  FxRecord.Recorder;

const
  WM_FXRECORD_NOTICE = WM_APP + $520;

type
  TFxRecordNoticeLevel = (fnInfo, fnWarning, fnCritical, fnRecovery);

  PFxRecordNotice = ^TFxRecordNotice;
  TFxRecordNotice = record
    Level: TFxRecordNoticeLevel;
    Text: string;
  end;

  TFxRecordMonitor = class(TThread)
  private
    FWindowHandle: HWND;
    FSettings: TFxRecordSettings;
    FStopEvent: TEvent;
    FRecorder: TFxSourceRecorder;
    FAlertTicks: TDictionary<string, UInt64>;
    FDiskState: Integer;
    FDiskFreeGB: Double;
    FLiveState: Integer;
    FLiveDetail: string;
    FLastSessionId: string;
    FLastPublishSeq: Int64;
    FManifestFailureTick: UInt64;
    FLastStatusWriteTick: UInt64;
    FLastAlertId: string;
    FLastAlertKey: string;
    FLastAlertSeverity: string;
    FLastAlertSubject: string;
    FLastAlertText: string;
    FLastAlertUtc: string;
    procedure Notice(const ALevel: TFxRecordNoticeLevel;
                     const AText: string);
    procedure Alert(const AKey,
                    ASubject,
                    AText: string;
                    const ALevel: TFxRecordNoticeLevel);
    procedure CheckDisk();
    procedure CheckLiveManifest();
    procedure RecorderEvent(const ALevel: TFxRecorderEventLevel;
                            const AText: string);
    function StatusFileName(): string;
    procedure PublishStatus(const AStopped: Boolean = False;
                            const AForce: Boolean = False);
  protected
    procedure Execute(); override;
  public
    constructor Create(const AWindowHandle: HWND;
                       const ASettings: TFxRecordSettings);
    destructor Destroy(); override;
    procedure Stop();
  end;

implementation

uses
  System.DateUtils,
  System.IOUtils,
  System.JSON;

function JsonText(const AObject: TJSONObject;
                  const AName: string): string;
var
  Pair: TJSONPair;
begin
  Result := '';
  Pair := AObject.Get(AName);
  if Assigned(Pair) and Assigned(Pair.JsonValue) then
    Result := Pair.JsonValue.Value;
end;

function UtcText(): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"',
                           TTimeZone.Local.ToUniversalTime(Now));
end;

function NoticeLevelText(const ALevel: TFxRecordNoticeLevel): string;
begin
  case ALevel of
    fnWarning: Result := 'warning';
    fnCritical: Result := 'critical';
    fnRecovery: Result := 'recovery';
  else
    Result := 'info';
  end;
end;

function TryReadSharedTextFile(const AFileName: string;
                               out AText: string;
                               out ALastWriteUtc: TDateTime): Boolean;
const
  MAX_MANIFEST_BYTES = 1024 * 1024;
var
  FileHandle: THandle;
  FileSize: DWORD;
  FileSizeHigh: DWORD;
  Bytes: TBytes;
  BytesRead: DWORD;
  TotalRead: Integer;
  LastWriteTime: TFileTime;
  SystemTime: TSystemTime;
begin
  Result := False;
  AText := '';
  ALastWriteUtc := 0;
  FileHandle := CreateFile(PChar(AFileName), GENERIC_READ,
                           FILE_SHARE_READ or FILE_SHARE_WRITE or
                           FILE_SHARE_DELETE, nil, OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,
                           0);
  if FileHandle = INVALID_HANDLE_VALUE then
    Exit;
  try
    FileSizeHigh := 0;
    SetLastError(NO_ERROR);
    FileSize := GetFileSize(FileHandle, @FileSizeHigh);
    if ((FileSize = INVALID_FILE_SIZE) and (GetLastError() <> NO_ERROR)) or
       (FileSizeHigh <> 0) or (FileSize = 0) or
       (FileSize > MAX_MANIFEST_BYTES) then
      Exit;
    if not GetFileTime(FileHandle, nil, nil, @LastWriteTime) or
       not FileTimeToSystemTime(LastWriteTime, SystemTime) then
      Exit;

    SetLength(Bytes, Integer(FileSize));
    TotalRead := 0;
    while TotalRead < Length(Bytes) do
      begin
        BytesRead := 0;
        if not ReadFile(FileHandle, Bytes[TotalRead],
                        Length(Bytes) - TotalRead, BytesRead, nil) or
           (BytesRead = 0) then
          Exit;
        Inc(TotalRead, BytesRead);
      end;

    ALastWriteUtc := SystemTimeToDateTime(SystemTime);
    AText := TEncoding.UTF8.GetString(Bytes);
    if (AText <> '') and (AText[1] = #$FEFF) then
      Delete(AText, 1, 1);
    Result := True;
  finally
    CloseHandle(FileHandle);
  end;
end;

constructor TFxRecordMonitor.Create(const AWindowHandle: HWND;
                                    const ASettings: TFxRecordSettings);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWindowHandle := AWindowHandle;
  FSettings := ASettings;
  FStopEvent := TEvent.Create(nil, True, False, '');
  FAlertTicks := TDictionary<string, UInt64>.Create();
  FRecorder := TFxSourceRecorder.Create(FSettings, RecorderEvent);
  FDiskState := -1;
  FDiskFreeGB := -1;
  FLiveState := -1;
  FLiveDetail := 'starting';
  FLastPublishSeq := -1;
  FManifestFailureTick := 0;
  FLastStatusWriteTick := 0;
end;

destructor TFxRecordMonitor.Destroy();
begin
  FRecorder.Free();
  FAlertTicks.Free();
  FStopEvent.Free();
  inherited Destroy();
end;

procedure TFxRecordMonitor.Stop();
begin
  Terminate();
  FStopEvent.SetEvent();
end;

procedure TFxRecordMonitor.Notice(const ALevel: TFxRecordNoticeLevel;
                                  const AText: string);
var
  Item: PFxRecordNotice;
begin
  New(Item);
  Item^.Level := ALevel;
  Item^.Text := AText;
  if not PostMessage(FWindowHandle, WM_FXRECORD_NOTICE, 0, LPARAM(Item)) then
    Dispose(Item);
end;

procedure TFxRecordMonitor.Alert(const AKey,
                                 ASubject,
                                 AText: string;
                                 const ALevel: TFxRecordNoticeLevel);
var
  NowTick: UInt64;
  PreviousTick: UInt64;
begin
  NowTick := GetTickCount();
  if FAlertTicks.TryGetValue(AKey, PreviousTick) and
     ((NowTick - PreviousTick) < 60000) then
    Exit;

  FAlertTicks.AddOrSetValue(AKey, NowTick);
  FLastAlertId := FormatDateTime('yyyymmddhhnnsszzz', Now) + '-' + AKey;
  FLastAlertKey := AKey;
  FLastAlertSeverity := NoticeLevelText(ALevel);
  FLastAlertSubject := ASubject;
  FLastAlertText := AText;
  FLastAlertUtc := UtcText();
  Notice(ALevel, AText);
end;

procedure TFxRecordMonitor.RecorderEvent(const ALevel: TFxRecorderEventLevel;
                                         const AText: string);
begin
  case ALevel of
    relWarning:
      begin
        Alert('recording-warning', 'WARNING: recording needs attention',
              AText, fnWarning);
      end;
    relCritical:
      begin
        Alert('recording-error', 'CRITICAL: recording failure',
              AText, fnCritical);
      end;
    relRecovery: Notice(fnRecovery, AText);
  else
    Notice(fnInfo, AText);
  end;
end;

procedure TFxRecordMonitor.CheckDisk();
var
  FreeAvailable: Int64;
  TotalBytes: Int64;
  TotalFree: Int64;
  FreeGB: Double;
  NewState: Integer;
begin
  if not DirectoryExists(FSettings.ArchivePath) then
    ForceDirectories(FSettings.ArchivePath);

  if not GetDiskFreeSpaceEx(PChar(FSettings.ArchivePath),
                            FreeAvailable,
                            TotalBytes,
                            @TotalFree) then
    begin
      if FDiskState <> 3 then
        Alert('disk-query', 'CRITICAL: archive disk unavailable',
              'FxRecord cannot access the archive disk: ' +
              FSettings.ArchivePath + '. ' + SysErrorMessage(GetLastError()),
              fnCritical);
      FDiskState := 3;
      FDiskFreeGB := -1;
      Exit;
    end;

  FreeGB := FreeAvailable / 1024 / 1024 / 1024;
  FDiskFreeGB := FreeGB;
  if FreeGB <= FSettings.CriticalFreeGB then
    NewState := 2
  else if FreeGB <= FSettings.WarningFreeGB then
    NewState := 1
  else
    NewState := 0;

  if NewState = FDiskState then
    Exit;

  case NewState of
    2: Alert('disk-critical', 'CRITICAL: archive disk space',
             Format('Only %.1f GB is available in %s.',
                    [FreeGB, FSettings.ArchivePath]), fnCritical);
    1: Alert('disk-warning', 'WARNING: archive disk space',
             Format('Only %.1f GB is available in %s.',
                    [FreeGB, FSettings.ArchivePath]), fnWarning);
    0:
      if FDiskState > 0 then
        begin
          Notice(fnRecovery, Format('Archive disk space recovered: %.1f GB available.',
                                    [FreeGB]));
          FAlertTicks.Remove('disk-query');
          FAlertTicks.Remove('disk-critical');
          FAlertTicks.Remove('disk-warning');
        end;
  end;
  FDiskState := NewState;
end;

procedure TFxRecordMonitor.CheckLiveManifest();
var
  FileName: string;
  ManifestText: string;
  LastWriteUtc: TDateTime;
  AgeSeconds: Int64;
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
  SessionId: string;
  PublishText: string;
  PublishSeq: Int64;
  NewState: Integer;
  PreviousDetail: string;
  NowTick: UInt64;
  Attempt: Integer;
  ReadSucceeded: Boolean;
  JsonValid: Boolean;
begin
  FileName := TPath.Combine(FSettings.StreamPath, 'live.json');
  if not FileExists(FileName) then
    begin
      FManifestFailureTick := 0;
      NewState := 0;
      if FSettings.RequireLiveStream then
        NewState := 2;
      if NewState = 2 then
        FLiveDetail := 'missing'
      else
        FLiveDetail := 'waiting';
      if NewState <> FLiveState then
        begin
          if NewState = 2 then
            Alert('live-missing', 'WARNING: live manifest missing',
                  'FxRecord cannot find ' + FileName + '.', fnWarning)
          else
            Notice(fnInfo, 'Waiting for a live broadcast.');
        end;
      FLiveState := NewState;
      Exit;
    end;

  ReadSucceeded := False;
  JsonValid := False;
  JsonValue := nil;
  for Attempt := 1 to 3 do
    begin
      ReadSucceeded := TryReadSharedTextFile(FileName, ManifestText,
                                             LastWriteUtc);
      if ReadSucceeded then
        begin
          JsonValue := TJSONObject.ParseJSONValue(ManifestText);
          JsonValid := JsonValue is TJSONObject;
          if JsonValid then
            Break;
          FreeAndNil(JsonValue);
        end;
      if Attempt < 3 then
        Sleep(25);
    end;

  if not JsonValid then
    begin
      NowTick := GetTickCount();
      if FManifestFailureTick = 0 then
        FManifestFailureTick := NowTick;
      if (NowTick - FManifestFailureTick) >=
         UInt64(FSettings.LiveStaleSeconds) * 1000 then
        begin
          PreviousDetail := FLiveDetail;
          FLiveState := 2;
          if ReadSucceeded then
            FLiveDetail := 'invalid'
          else
            FLiveDetail := 'unreadable';
          if PreviousDetail <> FLiveDetail then
            begin
              if ReadSucceeded then
                Alert('live-json', 'WARNING: invalid live manifest',
                      FileName + ' has remained invalid for ' +
                      IntToStr(FSettings.LiveStaleSeconds) + ' seconds.',
                      fnWarning)
              else
                Alert('live-unreadable', 'WARNING: live manifest unavailable',
                      FileName + ' could not be read for ' +
                      IntToStr(FSettings.LiveStaleSeconds) + ' seconds.',
                      fnWarning);
            end;
        end;
      Exit;
    end;

  FManifestFailureTick := 0;
  AgeSeconds := SecondsBetween(LastWriteUtc,
                               TTimeZone.Local.ToUniversalTime(Now));
  if AgeSeconds > FSettings.LiveStaleSeconds then
    begin
      NewState := 2;
      FLiveDetail := 'stale';
    end
  else
    begin
      NewState := 1;
      FLiveDetail := 'live';
    end;

  if NewState <> FLiveState then
    begin
      if NewState = 2 then
        Alert('live-stale', 'WARNING: live stream stopped updating',
              Format('%s has not changed for %d seconds.', [FileName, AgeSeconds]),
              fnWarning)
      else if FLiveState = 2 then
        begin
          Notice(fnRecovery, 'Live stream updates resumed.');
          FAlertTicks.Remove('live-missing');
          FAlertTicks.Remove('live-stale');
          FAlertTicks.Remove('live-json');
          FAlertTicks.Remove('live-unreadable');
          FAlertTicks.Remove('sequence-backwards');
        end
      else
        Notice(fnInfo, 'Live stream detected.');
    end;
  FLiveState := NewState;

  if NewState <> 1 then
    begin
      JsonValue.Free();
      Exit;
    end;

  try
    JsonObject := TJSONObject(JsonValue);
    FRecorder.ProcessManifest(JsonObject);
    SessionId := JsonText(JsonObject, 'sessionId');
    PublishText := JsonText(JsonObject, 'publishSeq');
    if not TryStrToInt64(PublishText, PublishSeq) then
      PublishSeq := -1;

    if (SessionId <> '') and (SessionId <> FLastSessionId) then
      begin
        Notice(fnInfo, 'Active broadcast session: ' + SessionId);
        FLastSessionId := SessionId;
        FLastPublishSeq := -1;
      end;

    if (PublishSeq >= 0) and (FLastPublishSeq >= 0) and
       (PublishSeq < FLastPublishSeq) then
      Alert('sequence-backwards', 'WARNING: fragment sequence moved backwards',
            Format('Publish sequence changed from %d to %d in session %s.',
                   [FLastPublishSeq, PublishSeq, SessionId]), fnWarning);
    FLastPublishSeq := PublishSeq;
  finally
    JsonValue.Free();
  end;
end;

function TFxRecordMonitor.StatusFileName(): string;
var
  WebRoot: string;
begin
  WebRoot := ExtractFileDir(ExcludeTrailingPathDelimiter(FSettings.StreamPath));
  Result := TPath.Combine(TPath.Combine(WebRoot, 'FxAlert'), 'status.json');
end;

procedure TFxRecordMonitor.PublishStatus(const AStopped,
                                               AForce: Boolean);
var
  NowTick: UInt64;
  TargetName: string;
  TempName: string;
  StateText: string;
  DiskText: string;
  Json: TJSONObject;
  AlertJson: TJSONObject;
begin
  NowTick := GetTickCount();
  if not AForce and (FLastStatusWriteTick <> 0) and
     ((NowTick - FLastStatusWriteTick) < 5000) then
    Exit;

  if AStopped then
    StateText := 'stopped'
  else if (FDiskState >= 2) then
    StateText := 'critical'
  else if (FDiskState = 1) or (FLiveState = 2) then
    StateText := 'warning'
  else if (FDiskState < 0) or (FLiveState < 0) then
    StateText := 'starting'
  else
    StateText := 'ok';

  case FDiskState of
    0: DiskText := 'ok';
    1: DiskText := 'warning';
    2: DiskText := 'critical';
    3: DiskText := 'unavailable';
  else
    DiskText := 'starting';
  end;

  TargetName := StatusFileName();
  ForceDirectories(ExtractFileDir(TargetName));
  TempName := TargetName + '.tmp';

  Json := TJSONObject.Create();
  try
    Json.AddPair('version', TJSONNumber.Create(1));
    Json.AddPair('service', 'FxRecord');
    Json.AddPair('computer', GetEnvironmentVariable('COMPUTERNAME'));
    Json.AddPair('heartbeatUtc', UtcText());
    Json.AddPair('state', StateText);
    Json.AddPair('diskState', DiskText);
    Json.AddPair('diskFreeGB', TJSONNumber.Create(FDiskFreeGB));
    Json.AddPair('streamState', FLiveDetail);
    Json.AddPair('sessionId', FLastSessionId);
    Json.AddPair('publishSeq', TJSONNumber.Create(FLastPublishSeq));
    if FRecorder.IsRecording() then
      Json.AddPair('recordingActive', TJSONTrue.Create())
    else
      Json.AddPair('recordingActive', TJSONFalse.Create());
    Json.AddPair('recordingFile', FRecorder.ActiveFileName);
    Json.AddPair('recordingBytes', TJSONNumber.Create(FRecorder.BytesWritten));
    Json.AddPair('recordedSequence', TJSONNumber.Create(FRecorder.LastSequence));

    AlertJson := TJSONObject.Create();
    AlertJson.AddPair('id', FLastAlertId);
    AlertJson.AddPair('key', FLastAlertKey);
    AlertJson.AddPair('severity', FLastAlertSeverity);
    AlertJson.AddPair('subject', FLastAlertSubject);
    AlertJson.AddPair('message', FLastAlertText);
    AlertJson.AddPair('createdUtc', FLastAlertUtc);
    Json.AddPair('alert', AlertJson);

    TFile.WriteAllText(TempName, Json.ToJSON(), TEncoding.UTF8);
    if not MoveFileEx(PChar(TempName), PChar(TargetName),
                      MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
      RaiseLastOSError();
    FLastStatusWriteTick := NowTick;
  finally
    Json.Free();
    if FileExists(TempName) then
      DeleteFile(TempName);
  end;
end;

procedure TFxRecordMonitor.Execute();
begin
  Notice(fnInfo, 'Recording and monitoring started.');
  Notice(fnInfo, 'FxAlert status: ' + StatusFileName());
  while not Terminated do
    begin
      try
        CheckDisk();
        CheckLiveManifest();
        PublishStatus(False, False);
      except
        on E: Exception do
          Alert('monitor-exception', 'CRITICAL: monitor error',
                E.ClassName + ': ' + E.Message, fnCritical);
      end;

      if FStopEvent.WaitFor(FSettings.PollIntervalMs) = wrSignaled then
        Break;
    end;
  FRecorder.Stop();
  try
    PublishStatus(True, True);
  except
    { The monitor is already stopping; a stale heartbeat also tells FxAlert. }
  end;
  Notice(fnInfo, 'Recording and monitoring stopped.');
end;

end.
