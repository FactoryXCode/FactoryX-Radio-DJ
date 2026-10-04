unit FxRecord.Recorder;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.JSON,
  FxRecord.Config;

type
  TFxRecorderEventLevel = (relInfo, relWarning, relCritical, relRecovery);
  TFxRecorderEvent = procedure(const ALevel: TFxRecorderEventLevel;
                               const AText: string) of object;

  TFxSourceRecorder = class
  private
    FSettings: TFxRecordSettings;
    FOnEvent: TFxRecorderEvent;
    FFileHandle: THandle;
    FActivePartialName: string;
    FActiveFinalName: string;
    FActiveStarted: TDateTime;
    FSegmentStartHint: TDateTime;
    FNextBoundary: TDateTime;
    FBytesWritten: Int64;
    FSessionId: string;
    FNextSequence: Int64;
    FLastSequence: Int64;
    FLastProgressTick: UInt64;
    FHadWriteError: Boolean;
    procedure Event(const ALevel: TFxRecorderEventLevel;
                    const AText: string);
    function StartSegment(const AInitFile: string): Boolean;
    procedure CloseSegment(const AReason: string);
    function AppendFragment(const AFileName: string;
                            const ASequence: Int64): Boolean;
    function BuildFragmentName(const APrefix, AExtension: string;
                               const ADigits: Integer;
                               const ASequence: Int64): string;
    function NextSplitBoundary(const AValue: TDateTime): TDateTime;
    function UniqueFinalName(const AStarted: TDateTime): string;
    procedure RecoverPartialFiles();
    procedure CleanupExpiredFiles();
    procedure ReportProgress();
  public
    constructor Create(const ASettings: TFxRecordSettings;
                       const AOnEvent: TFxRecorderEvent);
    destructor Destroy(); override;
    procedure ProcessManifest(const AManifest: TJSONObject);
    procedure Stop();
    property ActiveFileName: string read FActiveFinalName;
    property BytesWritten: Int64 read FBytesWritten;
    property LastSequence: Int64 read FLastSequence;
    function IsRecording(): Boolean;
  end;

implementation

uses
  System.DateUtils,
  System.IOUtils;

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

function JsonInt64(const AObject: TJSONObject;
                   const AName: string;
                   const ADefault: Int64): Int64;
begin
  if not TryStrToInt64(JsonText(AObject, AName), Result) then
    Result := ADefault;
end;

function JsonInteger(const AObject: TJSONObject;
                     const AName: string;
                     const ADefault: Integer): Integer;
var
  Value: Int64;
begin
  Value := JsonInt64(AObject, AName, ADefault);
  if (Value < Low(Integer)) or (Value > High(Integer)) then
    Result := ADefault
  else
    Result := Integer(Value);
end;

function TryReadSharedBytes(const AFileName: string;
                            out ABytes: TBytes): Boolean;
const
  MAX_SOURCE_FILE_BYTES = 256 * 1024 * 1024;
var
  FileHandle: THandle;
  FileSize: DWORD;
  FileSizeHigh: DWORD;
  BytesRead: DWORD;
  TotalRead: Integer;
begin
  Result := False;
  SetLength(ABytes, 0);
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
       (FileSize > MAX_SOURCE_FILE_BYTES) then
      Exit;
    SetLength(ABytes, Integer(FileSize));
    TotalRead := 0;
    while TotalRead < Length(ABytes) do
      begin
        BytesRead := 0;
        if not ReadFile(FileHandle, ABytes[TotalRead],
                        Length(ABytes) - TotalRead, BytesRead, nil) or
           (BytesRead = 0) then
          begin
            SetLength(ABytes, 0);
            Exit;
          end;
        Inc(TotalRead, BytesRead);
      end;
    Result := True;
  finally
    CloseHandle(FileHandle);
  end;
end;

function WriteAll(const AHandle: THandle;
                  const ABytes: TBytes): Boolean;
var
  BytesWritten: DWORD;
  TotalWritten: Integer;
begin
  Result := False;
  if (AHandle = INVALID_HANDLE_VALUE) or (Length(ABytes) = 0) then
    Exit;
  TotalWritten := 0;
  while TotalWritten < Length(ABytes) do
    begin
      BytesWritten := 0;
      if not WriteFile(AHandle, ABytes[TotalWritten],
                       Length(ABytes) - TotalWritten, BytesWritten, nil) or
         (BytesWritten = 0) then
        Exit;
      Inc(TotalWritten, BytesWritten);
    end;
  Result := True;
end;

function TryGetLastWriteLocal(const AFileName: string;
                              out AValue: TDateTime): Boolean;
var
  FileHandle: THandle;
  UtcFileTime: TFileTime;
  LocalFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  Result := False;
  AValue := 0;
  FileHandle := CreateFile(PChar(AFileName), FILE_READ_ATTRIBUTES,
                           FILE_SHARE_READ or FILE_SHARE_WRITE or
                           FILE_SHARE_DELETE, nil, OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
    Exit;
  try
    if not GetFileTime(FileHandle, nil, nil, @UtcFileTime) or
       not FileTimeToLocalFileTime(UtcFileTime, LocalFileTime) or
       not FileTimeToSystemTime(LocalFileTime, SystemTime) then
      Exit;
    AValue := SystemTimeToDateTime(SystemTime);
    Result := True;
  finally
    CloseHandle(FileHandle);
  end;
end;

constructor TFxSourceRecorder.Create(const ASettings: TFxRecordSettings;
                                     const AOnEvent: TFxRecorderEvent);
begin
  inherited Create();
  FSettings := ASettings;
  FOnEvent := AOnEvent;
  FFileHandle := INVALID_HANDLE_VALUE;
  FNextSequence := -1;
  FLastSequence := -1;
  FLastProgressTick := 0;
  RecoverPartialFiles();
  CleanupExpiredFiles();
end;

destructor TFxSourceRecorder.Destroy();
begin
  Stop();
  inherited Destroy();
end;

procedure TFxSourceRecorder.Event(const ALevel: TFxRecorderEventLevel;
                                  const AText: string);
begin
  if Assigned(FOnEvent) then
    FOnEvent(ALevel, AText);
end;

function TFxSourceRecorder.IsRecording(): Boolean;
begin
  Result := FFileHandle <> INVALID_HANDLE_VALUE;
end;

function TFxSourceRecorder.NextSplitBoundary(
  const AValue: TDateTime): TDateTime;
var
  DayStart: TDateTime;
  MinuteOfDay: Integer;
  BoundaryMinute: Integer;
begin
  DayStart := Trunc(AValue);
  MinuteOfDay := HourOf(AValue) * 60 + MinuteOf(AValue);
  BoundaryMinute := ((MinuteOfDay div FSettings.SplitMinutes) + 1) *
                    FSettings.SplitMinutes;
  Result := DayStart + (BoundaryMinute / 1440);
end;

function TFxSourceRecorder.UniqueFinalName(
  const AStarted: TDateTime): string;
var
  BaseName: string;
  Candidate: string;
  Index: Integer;
begin
  BaseName := FormatDateTime('yyyy-mm-dd-hhnnss', AStarted);
  Candidate := TPath.Combine(FSettings.ArchivePath, BaseName + '.mp4');
  Index := 1;
  while FileExists(Candidate) or FileExists(Candidate + '.partial') do
    begin
      Candidate := TPath.Combine(FSettings.ArchivePath,
        Format('%s-%2.2d.mp4', [BaseName, Index]));
      Inc(Index);
    end;
  Result := Candidate;
end;

procedure TFxSourceRecorder.RecoverPartialFiles();
var
  Search: TSearchRec;
  SourceName: string;
  TargetName: string;
begin
  if not DirectoryExists(FSettings.ArchivePath) then
    Exit;
  if FindFirst(TPath.Combine(FSettings.ArchivePath, '*.mp4.partial'),
               faAnyFile, Search) <> 0 then
    Exit;
  try
    repeat
      SourceName := TPath.Combine(FSettings.ArchivePath, Search.Name);
      TargetName := Copy(SourceName, 1, Length(SourceName) - Length('.partial'));
      if FileExists(TargetName) then
        TargetName := ChangeFileExt(TargetName, '.recovered.mp4');
      if MoveFileEx(PChar(SourceName), PChar(TargetName),
                    MOVEFILE_WRITE_THROUGH) then
        Event(relWarning, 'Recovered unfinished recording: ' + TargetName)
      else
        Event(relWarning, 'Could not recover unfinished recording: ' +
                          SourceName + '. ' + SysErrorMessage(GetLastError()));
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

procedure TFxSourceRecorder.CleanupExpiredFiles();
var
  Search: TSearchRec;
  FileName: string;
  Cutoff: TDateTime;
  FileTime: TDateTime;
begin
  if not DirectoryExists(FSettings.ArchivePath) then
    Exit;
  Cutoff := IncDay(Now, -FSettings.RetentionDays);
  if FindFirst(TPath.Combine(FSettings.ArchivePath, '*.mp4'),
               faAnyFile, Search) <> 0 then
    Exit;
  try
    repeat
      if (Search.Attr and faDirectory) <> 0 then
        Continue;
      FileName := TPath.Combine(FSettings.ArchivePath, Search.Name);
      if not TryGetLastWriteLocal(FileName, FileTime) then
        Continue;
      if FileTime >= Cutoff then
        Continue;
      if DeleteFile(PChar(FileName)) then
        Event(relInfo, 'Expired recording removed: ' + FileName)
      else
        Event(relWarning, 'Could not remove expired recording: ' + FileName +
                          '. ' + SysErrorMessage(GetLastError()));
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

function TFxSourceRecorder.StartSegment(const AInitFile: string): Boolean;
var
  InitBytes: TBytes;
begin
  Result := False;
  if not DirectoryExists(FSettings.ArchivePath) and
     not ForceDirectories(FSettings.ArchivePath) then
    begin
      Event(relCritical, 'Cannot create archive folder: ' +
                         FSettings.ArchivePath);
      Exit;
    end;
  if not TryReadSharedBytes(AInitFile, InitBytes) then
    begin
      Event(relWarning, 'Waiting for readable initialization file: ' +
                        AInitFile);
      Exit;
    end;

  if FSegmentStartHint > 0 then
    begin
      FActiveStarted := FSegmentStartHint;
      FSegmentStartHint := 0;
    end
  else
    FActiveStarted := Now;
  FNextBoundary := NextSplitBoundary(FActiveStarted);
  FActiveFinalName := UniqueFinalName(FActiveStarted);
  FActivePartialName := FActiveFinalName + '.partial';
  FFileHandle := CreateFile(PChar(FActivePartialName), GENERIC_WRITE,
                            FILE_SHARE_READ, nil, CREATE_NEW,
                            FILE_ATTRIBUTE_NORMAL or
                            FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if FFileHandle = INVALID_HANDLE_VALUE then
    begin
      Event(relCritical, 'Cannot create recording: ' + FActivePartialName +
                         '. ' + SysErrorMessage(GetLastError()));
      Exit;
    end;
  if not WriteAll(FFileHandle, InitBytes) then
    begin
      Event(relCritical, 'Cannot write MP4 initialization data to ' +
                         FActivePartialName + '. ' +
                         SysErrorMessage(GetLastError()));
      CloseHandle(FFileHandle);
      FFileHandle := INVALID_HANDLE_VALUE;
      Exit;
    end;
  FlushFileBuffers(FFileHandle);
  FBytesWritten := Length(InitBytes);
  FHadWriteError := False;
  FLastProgressTick := GetTickCount();
  Event(relInfo, 'Recording started: ' + FActiveFinalName);
  Event(relInfo, 'Current recording file: ' + FActiveFinalName);
  Result := True;
end;

procedure TFxSourceRecorder.CloseSegment(const AReason: string);
var
  Finalized: Boolean;
begin
  if FFileHandle = INVALID_HANDLE_VALUE then
    Exit;
  FlushFileBuffers(FFileHandle);
  CloseHandle(FFileHandle);
  FFileHandle := INVALID_HANDLE_VALUE;
  Finalized := False;
  if not FHadWriteError then
    Finalized := MoveFileEx(PChar(FActivePartialName),
                            PChar(FActiveFinalName),
                            MOVEFILE_WRITE_THROUGH);
  if Finalized then
    begin
      Event(relInfo, Format('Recording closed (%s): %s (%.1f MB)',
        [AReason, FActiveFinalName, FBytesWritten / 1024 / 1024]));
      CleanupExpiredFiles();
    end
  else if FHadWriteError then
    Event(relCritical, 'Recording kept as incomplete: ' + FActivePartialName)
  else
    Event(relCritical, 'Could not finalize recording ' + FActivePartialName +
      '. ' + SysErrorMessage(GetLastError()));
  FActivePartialName := '';
  FActiveFinalName := '';
  FBytesWritten := 0;
  FLastProgressTick := 0;
end;

function TFxSourceRecorder.AppendFragment(const AFileName: string;
                                          const ASequence: Int64): Boolean;
var
  FragmentBytes: TBytes;
begin
  Result := False;
  if not TryReadSharedBytes(AFileName, FragmentBytes) then
    Exit;
  if not WriteAll(FFileHandle, FragmentBytes) then
    begin
      FHadWriteError := True;
      Event(relCritical, 'Recording write failed for ' + FActivePartialName +
        '. ' + SysErrorMessage(GetLastError()));
      CloseSegment('write failure');
      Exit;
    end;
  FlushFileBuffers(FFileHandle);
  Inc(FBytesWritten, Length(FragmentBytes));
  FLastSequence := ASequence;
  Result := True;
end;

function TFxSourceRecorder.BuildFragmentName(const APrefix,
  AExtension: string; const ADigits: Integer;
  const ASequence: Int64): string;
var
  SequenceText: string;
begin
  SequenceText := IntToStr(ASequence);
  if Length(SequenceText) < ADigits then
    SequenceText := StringOfChar('0', ADigits - Length(SequenceText)) +
                    SequenceText;
  Result := APrefix + SequenceText + AExtension;
end;

procedure TFxSourceRecorder.ReportProgress();
var
  NowTick: UInt64;
begin
  if not IsRecording() then
    Exit;
  NowTick := GetTickCount();
  if (FLastProgressTick <> 0) and
     ((NowTick - FLastProgressTick) < 60000) then
    Exit;
  FLastProgressTick := NowTick;
  Event(relInfo, Format('Current recording: %s (%.1f MB, fragment %d)',
    [FActiveFinalName, FBytesWritten / 1024 / 1024, FLastSequence]));
end;

procedure TFxSourceRecorder.ProcessManifest(const AManifest: TJSONObject);
var
  SessionId: string;
  InitName: string;
  Prefix: string;
  Extension: string;
  FirstSequence: Int64;
  LastSequence: Int64;
  Digits: Integer;
  FragmentTargetMs: Integer;
  FragmentName: string;
  FragmentPath: string;
  InitPath: string;
begin
  if not SameText(JsonText(AManifest, 'live'), 'true') then
    Exit;
  SessionId := JsonText(AManifest, 'sessionId');
  if SessionId = '' then
    SessionId := 'unknown';
  InitName := ExtractFileName(JsonText(AManifest, 'init'));
  if InitName = '' then
    InitName := 'init.mp4';
  Prefix := ExtractFileName(JsonText(AManifest, 'prefix'));
  if Prefix = '' then
    Prefix := 'patched_frag_';
  Extension := ExtractFileName(JsonText(AManifest, 'ext'));
  if Extension = '' then
    Extension := '.m4s';
  Digits := JsonInteger(AManifest, 'digits', 6);
  if (Digits < 1) or (Digits > 18) then
    Digits := 6;
  FirstSequence := JsonInt64(AManifest, 'first', -1);
  LastSequence := JsonInt64(AManifest, 'last', -1);
  if (FirstSequence < 0) or (LastSequence < FirstSequence) then
    Exit;

  if not SameText(FSessionId, SessionId) then
    begin
      if IsRecording() then
        CloseSegment('broadcast session changed');
      FSessionId := SessionId;
      FNextSequence := FirstSequence;
      FLastSequence := -1;
      FragmentTargetMs := JsonInteger(AManifest, 'fragmentTargetMs', 4000);
      if (FragmentTargetMs < 250) or (FragmentTargetMs > 60000) then
        FragmentTargetMs := 4000;
      FSegmentStartHint := IncMilliSecond(Now,
        -((LastSequence - FirstSequence + 1) * FragmentTargetMs));
      Event(relInfo, 'Recording broadcast session: ' + SessionId);
    end;

  if FNextSequence < FirstSequence then
    begin
      Event(relWarning, Format('Recording fragment gap: expected %d, first available is %d.',
                              [FNextSequence, FirstSequence]));
      FNextSequence := FirstSequence;
    end;
  InitPath := TPath.Combine(FSettings.StreamPath, InitName);

  while FNextSequence <= LastSequence do
    begin
      if IsRecording() and (Now >= FNextBoundary) then
        CloseSegment('scheduled rotation');
      if not IsRecording() and not StartSegment(InitPath) then
        Exit;
      FragmentName := BuildFragmentName(Prefix, Extension, Digits,
                                        FNextSequence);
      FragmentPath := TPath.Combine(FSettings.StreamPath, FragmentName);
      if not AppendFragment(FragmentPath, FNextSequence) then
        Exit;
      Inc(FNextSequence);
    end;
  ReportProgress();
end;

procedure TFxSourceRecorder.Stop();
begin
  CloseSegment('recorder stopped');
end;

end.
