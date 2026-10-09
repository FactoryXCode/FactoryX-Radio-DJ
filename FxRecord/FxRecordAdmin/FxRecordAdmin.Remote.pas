// FactoryX
//
// Copyright (c) FactoryX, Netherlands/Australia/Germany. All rights reserved.
//
// Project: Media Foundation - MFPack - Samples
// Project location: https://sourceforge.net/projects/MFPack
//                   https://github.com/FactoryXCode/MfPack
// Module: FxRecordAdmin.Remote.pas
// Kind: Pascal Unit
// Release date: 10-08-2026
// Language: ENU
//
// Revision Version: 4.0.0
// Description: Controls the remote FxRecord service and shared recorder settings.
//
// Company: FactoryX
// Intiator(s): Tony (maXcomX), Carmen (carmenh).
// Contributor(s): Tony Kalf (maXcomX), Carmen (carmenh).
//
//------------------------------------------------------------------------------
// CHANGE LOG
// Date       Person              Reason
// ---------- ------------------- ----------------------------------------------
// 24/08/2026 All                 Moby release  SDK 10.0.28000.2705  (Windows 11)
//------------------------------------------------------------------------------
//
// Remarks: Requires Windows 10 or higher.
//
// Related objects: -
// Related projects: MfPackX400
// Known Issues: -
//
// Compiler version: 23 up to 35
// SDK version: 10.0.28000.2705
//
// Todo: -
//
// =============================================================================
// Source: -
//==============================================================================
//
// LICENSE
//
// The contents of this file are subject to the Mozilla Public License
// Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// https://mozilla.org/MPL/2.0/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//
// Non commercial users may distribute this sourcecode provided that this
// header is included in full at the top of the file.
// Commercial users are not allowed to distribute this sourcecode as part of
// their product.
//
//==============================================================================
unit FxRecordAdmin.Remote;

interface

uses

  {WinApi}
  WinApi.Windows,
  WinApi.Messages,
  WinApi.WinSvc,
  {System}
  System.SysUtils,
  System.Classes,
  {Application}
  FxRecord.Config;

const
  FX_RECORD_ADMIN_RESULT = WM_APP + 241;
  FX_RECORD_ADMIN_SERVICE = 'FxRecord';


type
  TWideArguments = array[0..65535] of PWideChar;
  PWideArguments = ^TWideArguments;

  TFxAdminAction = (aaConnect,
                    aaRefresh,
                    aaStart,
                    aaStop,
                    aaRestart,
                    aaSave,
                    aaApply);


  TFxAdminConnection = record
    Machine: string;
    ConfigFile: string;
    ServerConfigFile: string;
  end;


  TFxAdminResult = class
  public
    Action: TFxAdminAction;
    State: DWORD;
    ProcessId: DWORD;
    ExitCode: DWORD;
    SpecificExitCode: DWORD;
    ServerConfigFile: string;
    ConfigText: string;
    LogText: string;
    StatusText: string;
    ErrorText: string;
    Notice: string;
    ConfigSaved: Boolean;
  end;


  TFxAdminWorker = class(TThread)
  private
    FWindow: HWND;
    FConnection: TFxAdminConnection;
    FAction: TFxAdminAction;
    FOriginalText: string;
    FNewText: string;

  protected
    procedure Execute(); override;

  public
    constructor Create(AWindow: HWND;
                       const AConnection: TFxAdminConnection;
                       AAction: TFxAdminAction;
                       const AOriginalText: string;
                       const ANewText: string);
  end;


  function ServiceStateText(AState: DWORD): string;
  function ConfigFileFromCommand(const ACommand: string): string;
  procedure ValidateConnection(const AConnection: TFxAdminConnection);

  procedure SettingsFromText(const AText, AServerConfigFile: string;
                             out ASettings: TFxRecordSettings);

  function SettingsToText(const AOriginalText: string;
                          const ASettings: TFxRecordSettings): string;

  procedure ValidateSettings(const ASettings: TFxRecordSettings);

  function ParseCommandLine(ACommand: PWideChar;
                            var ACount: Integer): PWideArguments; stdcall;

implementation

uses

  {System}
  System.IniFiles,
  System.IOUtils,
  System.StrUtils;

const
  Shell32Lib = 'shell32.dll';

procedure CheckResult(AResult: Boolean;
                      const AOperation: string);
var
  ErrorCode: DWORD;

begin

  if not AResult then
    begin
      ErrorCode := GetLastError();
      raise Exception.CreateFmt('%s: %s (Windows error %d).',
                                [AOperation, SysErrorMessage(ErrorCode), ErrorCode]);
    end;
end;


function ServiceStateText(AState: DWORD): string;
begin

  case AState of
    SERVICE_STOPPED: Result := 'Stopped';
    SERVICE_START_PENDING: Result := 'Starting';
    SERVICE_STOP_PENDING: Result := 'Stopping';
    SERVICE_RUNNING: Result := 'Running';
    SERVICE_CONTINUE_PENDING: Result := 'Continuing';
    SERVICE_PAUSE_PENDING: Result := 'Pausing';
    SERVICE_PAUSED: Result := 'Paused';
  else
    Result := 'Unknown';
  end;
end;


procedure ValidateConnection(const AConnection: TFxAdminConnection);
var
  Machine: string;

begin

  Machine := Trim(AConnection.Machine);

  if (Machine = '') or
     (Pos('\', Machine) > 0) or
     (Pos('/', Machine) > 0) or
     (Pos(':', Machine) > 0) or
     (Pos(' ', Machine) > 0) then
    raise Exception.Create('Enter a LAN computer name or IPv4 address. Use "." for this computer.');

  if (AConnection.ConfigFile = '') then
    raise Exception.Create('Enter the shared FxRecord INI filename.');

  if (Machine <> '.') and not StartsText(#92#92 + Machine + #92,
                                         AConnection.ConfigFile) then
    raise Exception.Create('The shared INI path must begin with \' + Machine + '\.');

  if not SameText(ExtractFileExt(AConnection.ConfigFile),
                                 '.ini') then
    raise Exception.Create('The shared configuration file must have an .ini extension.');
end;


function ConfigFileFromCommand(const ACommand: string): string;
var
  Arguments: PWideArguments;
  Count: Integer;
  I: Integer;

begin

  Arguments := ParseCommandLine(PWideChar(ACommand),
                                Count);

  CheckResult((Arguments <> nil),
               'Parse the registered service command');

  try
    if (Count = 0) or not SameText(ExtractFileName(Arguments^[0]),
                                                   'FxRecord.exe') then
      raise Exception.Create('The FxRecord service does not point to FxRecord.exe.');

    Result := ChangeFileExt(Arguments^[0],
                            '.ini');

    for I := 1 to Count - 1 do
      if SameText(Arguments^[I],
                  '--config') then
        begin
          if (I + 1 >= Count) then
            raise Exception.Create('The service command has no --config filename.');

          Result := Arguments^[I + 1];
          Break;
        end;

    if not TPath.IsPathRooted(Result) then
      raise Exception.Create('The service configuration filename must be an absolute server path.');

  finally
    LocalFree(HLOCAL(Arguments));
  end;
end;


function NewTextIni(const AText: string): TMemIniFile;
var
  Lines: TStringList;

begin

  Result := TMemIniFile.Create('');

  Lines := TStringList.Create;

  try
    Lines.Text := AText;
    Result.SetStrings(Lines);

  finally
    Lines.Free;
  end;
end;


procedure SettingsFromText(const AText: string;
                           const AServerConfigFile: string;
                           out ASettings: TFxRecordSettings);
var
  Ini: TMemIniFile;

begin

  // Relative paths belong to the server, never to the admin computer.
  SetDefaultFxRecordSettings(ASettings, ExtractFileDir(AServerConfigFile));
  Ini := NewTextIni(AText);

  try
    ASettings.Enabled := Ini.ReadBool('Recorder',
                                      'Enabled',
                                      ASettings.Enabled);

    ASettings.StreamPath := Ini.ReadString('Recorder',
                                           'StreamPath',
                                           ASettings.StreamPath);

    ASettings.ArchivePath := Ini.ReadString('Recorder',
                                            'ArchivePath',
                                            ASettings.ArchivePath);

    ASettings.PollIntervalMs := Ini.ReadInteger('Recorder',
                                                'PollIntervalMs',
                                                ASettings.PollIntervalMs);

    ASettings.RequireLiveStream := Ini.ReadBool('Recorder',
                                                'RequireLiveStream',
                                                ASettings.RequireLiveStream);

    ASettings.LiveStaleSeconds := Ini.ReadInteger('Recorder',
                                                  'LiveStaleSeconds',
                                                  ASettings.LiveStaleSeconds);

    ASettings.WarningFreeGB := Ini.ReadInteger('Recorder',
                                               'WarningFreeGB',
                                               ASettings.WarningFreeGB);

    ASettings.CriticalFreeGB := Ini.ReadInteger('Recorder',
                                                'CriticalFreeGB',
                                                ASettings.CriticalFreeGB);

    ASettings.FragmentDuration := Ini.ReadInteger('Archive',
                                                  'FragmentDuration',
                                                  ASettings.FragmentDuration);

    ASettings.RetentionDays := Ini.ReadInteger('Archive',
                                               'RetentionDays',
                                               ASettings.RetentionDays);

    ASettings.OutputProfile := Ini.ReadString('Archive',
                                              'OutputProfile',
                                              ASettings.OutputProfile);

    ASettings.Mp3SampleRate := Ini.ReadInteger('Audio',
                                               'Mp3SampleRate',
                                               ASettings.Mp3SampleRate);

    ASettings.Mp3BitRateKbps := Ini.ReadInteger('Audio',
                                                'Mp3BitRateKbps',
                                                ASettings.Mp3BitRateKbps);

    ASettings.AacSampleRate := Ini.ReadInteger('Audio',
                                               'AacSampleRate',
                                               ASettings.AacSampleRate);

    ASettings.AacBitRateKbps := Ini.ReadInteger('Audio',
                                                'AacBitRateKbps',
                                                ASettings.AacBitRateKbps);
  finally
    Ini.Free;
  end;
end;


procedure ValidateSettings(const ASettings: TFxRecordSettings);
begin

  if (Trim(ASettings.StreamPath) = '') or (Trim(ASettings.ArchivePath) = '') then
    raise Exception.Create('Stream and archive folders are required.');

  if (ASettings.FragmentDuration < 1) or (ASettings.FragmentDuration > 1440) then
    raise Exception.Create('Fragment duration must be between 1 and 1440 minutes.');

  if (ASettings.RetentionDays < 1) or (ASettings.RetentionDays > 3650) then
    raise Exception.Create('Retention must be between 1 and 3650 days.');

  if (ASettings.PollIntervalMs < 100) or (ASettings.PollIntervalMs > 60000) then
    raise Exception.Create('Polling interval must be between 100 and 60000 milliseconds.');

  if (ASettings.LiveStaleSeconds < 5) or (ASettings.LiveStaleSeconds > 3600) then
    raise Exception.Create('Live timeout must be between 5 and 3600 seconds.');

  if (ASettings.CriticalFreeGB < 1) or
     (ASettings.WarningFreeGB < ASettings.CriticalFreeGB) or (ASettings.WarningFreeGB > 100000) then
    raise Exception.Create('Disk warning must be at least the critical threshold, and both must be positive.');

  if SameText(ASettings.OutputProfile,
              'AVI-H264-MP3') then
    begin
      if not ((ASettings.Mp3SampleRate = 32000) or
             (ASettings.Mp3SampleRate = 44100) or
             (ASettings.Mp3SampleRate = 48000)) or not
             ((ASettings.Mp3BitRateKbps = 128) or
             (ASettings.Mp3BitRateKbps = 160) or
             (ASettings.Mp3BitRateKbps = 192)) then
        raise Exception.Create('Select a supported MP3 sample rate and bitrate.');
    end
  else
    if SameText(ASettings.OutputProfile, 'MP4-H264-AAC') then
      begin
        if not ((ASettings.AacSampleRate = 44100) or
               (ASettings.AacSampleRate = 48000)) or not
               ((ASettings.AacBitRateKbps = 96) or
               (ASettings.AacBitRateKbps = 128) or
               (ASettings.AacBitRateKbps = 160) or
               (ASettings.AacBitRateKbps = 192)) then
         raise Exception.Create('Select 44.1/48 kHz AAC at 96, 128, 160 or 192 kbps.');
      end
    else
      if not SameText(ASettings.OutputProfile, 'SourceCopy') then
        raise Exception.Create('Unsupported recording profile.');
end;


function SettingsToText(const AOriginalText: string;
                        const ASettings: TFxRecordSettings): string;
var
  Ini: TMemIniFile;
  Lines: TStringList;

begin

  ValidateSettings(ASettings);
  Ini := NewTextIni(AOriginalText);
  Lines := TStringList.Create;

  try
    Ini.WriteBool('Recorder',
                  'Enabled',
                  ASettings.Enabled);

    Ini.WriteString('Recorder',
                    'StreamPath',
                    ASettings.StreamPath);

    Ini.WriteString('Recorder',
                    'ArchivePath',
                    ASettings.ArchivePath);

    Ini.WriteInteger('Recorder',
                     'PollIntervalMs',
                     ASettings.PollIntervalMs);

    Ini.WriteBool('Recorder',
                  'RequireLiveStream',
                  ASettings.RequireLiveStream);

    Ini.WriteInteger('Recorder',
                     'LiveStaleSeconds',
                     ASettings.LiveStaleSeconds);

    Ini.WriteInteger('Recorder',
                     'WarningFreeGB',
                     ASettings.WarningFreeGB);

    Ini.WriteInteger('Recorder',
                     'CriticalFreeGB',
                     ASettings.CriticalFreeGB);

    Ini.WriteInteger('Archive',
                     'FragmentDuration',
                     ASettings.FragmentDuration);

    Ini.WriteInteger('Archive',
                     'RetentionDays',
                     ASettings.RetentionDays);

    Ini.WriteString('Archive',
                    'OutputProfile',
                    ASettings.OutputProfile);

    Ini.WriteInteger('Audio',
                     'Mp3SampleRate',
                     ASettings.Mp3SampleRate);

    Ini.WriteInteger('Audio',
                     'Mp3BitRateKbps',
                     ASettings.Mp3BitRateKbps);

    Ini.WriteInteger('Audio',
                     'AacSampleRate',
                     ASettings.AacSampleRate);

    Ini.WriteInteger('Audio',
                     'AacBitRateKbps',
                     ASettings.AacBitRateKbps);

    Ini.GetStrings(Lines);
    Result := Lines.Text;

  finally
    Lines.Free;
    Ini.Free;
  end;
end;


function RegisteredConfigFile(AService: SC_HANDLE): string;
var
  Needed: DWORD;
  Config: LPQUERY_SERVICE_CONFIG;

begin

  Needed := 0;
  QueryServiceConfig(AService,
                     nil,
                     0,
                     Needed);

  if (Needed = 0) then
    CheckResult(False,
                'Read the service configuration size');
  GetMem(Config, Needed);
  try
    CheckResult(QueryServiceConfig(AService,
                                   Config,
                                   Needed,
                                   Needed),
                                   'Read the service command');

    Result := ConfigFileFromCommand(Config.lpBinaryPathName);

  finally
    FreeMem(Config);
  end;
end;


procedure ReadServiceStatus(AService: SC_HANDLE;
                            AResult: TFxAdminResult);
var
  Status: SERVICE_STATUS_PROCESS;
  Needed: DWORD;

begin

  ZeroMemory(@Status,
             SizeOf(Status));

  CheckResult(QueryServiceStatusEx(AService,
                                   SC_STATUS_PROCESS_INFO,
                                   @Status,
                                   SizeOf(Status),
                                   Needed), 'Query FxRecord service status');

  AResult.State := Status.dwCurrentState;
  AResult.ProcessId := Status.dwProcessId;
  AResult.ExitCode := Status.dwWin32ExitCode;
  AResult.SpecificExitCode := Status.dwServiceSpecificExitCode;
end;


procedure WaitForState(AService: SC_HANDLE;
                       AState: DWORD;
                       AResult: TFxAdminResult);
var
  StartTick: DWORD;

begin

  StartTick := GetTickCount;

  repeat
    ReadServiceStatus(AService,
                      AResult);

    if (AResult.State = AState) then
      Exit;

    if (AState = SERVICE_RUNNING) and (AResult.State = SERVICE_STOPPED) then
      raise Exception.CreateFmt('FxRecord stopped during startup (exit codes %d / %d).',
                                [AResult.ExitCode, AResult.SpecificExitCode]);

    if (DWORD(GetTickCount - StartTick) >= 120000) then
      raise Exception.Create('FxRecord is still ' + LowerCase(ServiceStateText(AResult.State)) +
                             ' after two minutes. Refresh its status before another command.');

    Sleep(250);
  until False;
end;


procedure StartRecorder(AService: SC_HANDLE;
                        AResult: TFxAdminResult);
var
  Arguments: PChar;

begin

  ReadServiceStatus(AService,
                    AResult);

  if (AResult.State = SERVICE_RUNNING) then
    Exit;

  if (AResult.State = SERVICE_START_PENDING) then
    begin
      WaitForState(AService,
                   SERVICE_RUNNING,
                   AResult);
      Exit;
    end;

  if (AResult.State <> SERVICE_STOPPED) then
    raise Exception.Create('Wait until the FxRecord service is fully stopped.');

  Arguments := nil;
  CheckResult(StartService(AService,
                           0,
                           Arguments),
                           'Start FxRecord');

  WaitForState(AService,
               SERVICE_RUNNING,
               AResult);
end;


procedure StopRecorder(AService: SC_HANDLE;
                       AResult: TFxAdminResult);
var
  Status: TServiceStatus;

begin

  ReadServiceStatus(AService,
                    AResult);
  if (AResult.State = SERVICE_STOPPED) then
    Exit;

  if (AResult.State <> SERVICE_STOP_PENDING) then
    CheckResult(ControlService(AService,
                               SERVICE_CONTROL_STOP,
                               Status),
                               'Stop FxRecord');

  WaitForState(AService,
               SERVICE_STOPPED,
               AResult);
end;


function ReadSharedText(const AFileName: string;
                        ATailOnly: Boolean): string;
var
  Stream: TFileStream;
  Data: TBytes;
  Size: Int64;
  I: Integer;

begin

  Stream := TFileStream.Create(AFileName,
                               fmOpenRead or fmShareDenyNone);

  try
    Size := Stream.Size;

    if (not ATailOnly) and (Size > 1024 * 1024) then
      raise Exception.Create('The configuration/status file exceeds 1 MiB.');

    if ATailOnly and (Size > 131072) then
      Stream.Position := Size - 131072;

    SetLength(Data,
              Integer(Size - Stream.Position));

    if (Length(Data) > 0) then
      Stream.ReadBuffer(Data[0],
                        Length(Data));

    Result := TEncoding.UTF8.GetString(Data);

    if (Length(Result) > 0) and (Result[1] = #$FEFF) then
      Delete(Result,
             1,
             1);

    if ATailOnly and (Size > 131072) then
      begin
        I := Pos(#10,
                 Result);
        if (I > 0) then
          Delete(Result,
                 1,
                 I);
      end;

  finally
    Stream.Free;
  end;
end;


function SharePathForServerFile(const AConnection: TFxAdminConnection;
                                const AServerFile: string): string;
var
  BaseFolder: string;
  SharedFolder: string;

begin

  if (AConnection.Machine = '.') then
    Exit(AServerFile);

  BaseFolder := IncludeTrailingPathDelimiter(ExtractFileDir(AConnection.ServerConfigFile));
  SharedFolder := IncludeTrailingPathDelimiter(ExtractFileDir(AConnection.ConfigFile));

  if StartsText(BaseFolder,
                AServerFile) then
    Result := SharedFolder + Copy(AServerFile,
                                  Length(BaseFolder) + 1,
                                  MaxInt)
  else
    if (Length(AServerFile) > 2) and (AServerFile[2] = ':') then
      Result := #92#92 +
                AConnection.Machine +
                #92 +
                AServerFile[1] +
                '$' +
                Copy(AServerFile,
                     3,
                     MaxInt)
  else
    Result := AServerFile;
end;


procedure ReadRecorderFiles(const AConnection: TFxAdminConnection;
                            AResult: TFxAdminResult);
var
  Settings: TFxRecordSettings;
  StreamPath: string;
  StatusFile: string;

begin

  try
    AResult.LogText := ReadSharedText(ChangeFileExt(AConnection.ConfigFile,
                                                    '.log'),
                                                    True);
  except
    on E: Exception do AResult.LogText := 'Service log unavailable: ' + E.Message;
  end;

  try
    SettingsFromText(ReadSharedText(AConnection.ConfigFile,
                                    False),
                     AConnection.ServerConfigFile,
                     Settings);

    StreamPath := Settings.StreamPath;

    if not TPath.IsPathRooted(StreamPath) then
      StreamPath := TPath.GetFullPath(TPath.Combine(ExtractFileDir(AConnection.ServerConfigFile),
                                                    StreamPath));

    StatusFile := TPath.Combine(ExtractFileDir(ExcludeTrailingPathDelimiter(StreamPath)),
                               'FxAlert\status.json');


    AResult.StatusText := ReadSharedText(SharePathForServerFile(AConnection,
                                                                StatusFile),
                                         False);

  except
    on E: Exception do AResult.StatusText := 'FxAlert status unavailable: ' + E.Message;
  end;
end;


procedure ReplaceConfig(const AConnection: TFxAdminConnection;
                        const AOriginalText: string;
                        const ANewText: string;
                        AResult: TFxAdminResult);
var
  BackupFile: string;
  TemporaryFile: string;
  Id: TGUID;

begin

  if (ReadSharedText(AConnection.ConfigFile,
                     False) <> AOriginalText) then
    raise Exception.Create('The server ini-file changed since it was loaded. Reconnect before saving.');

  CreateGUID(Id);
  BackupFile := AConnection.ConfigFile +
                '.' +
                FormatDateTime('yyyymmdd-hhnnss',
                               Now) +
                '-' +
                GUIDToString(Id) +
                '.bak';


  CheckResult(CopyFile(PChar(AConnection.ConfigFile),
                       PChar(BackupFile),
                       True),
                       'Back up the FxRecord ini-file');

  TemporaryFile := AConnection.ConfigFile + '.' + GUIDToString(Id) + '.tmp';

  try
    TFile.WriteAllText(TemporaryFile,
                       ANewText,
                       TEncoding.UTF8);

    // Check again after staging, before replacing the live configuration.
    if (ReadSharedText(AConnection.ConfigFile,
                       False) <> AOriginalText) then
      raise Exception.Create('The server ini-file changed while saving. The original was preserved.');

    CheckResult(MoveFileEx(PChar(TemporaryFile),
                           PChar(AConnection.ConfigFile),
                           MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH),
                           'Replace the FxRecord ini-file');

    AResult.ConfigSaved := True;
    AResult.ConfigText := ANewText;
    AResult.Notice := 'Configuration saved. Backup: ' + BackupFile;

  finally
    DeleteFile(PChar(TemporaryFile));
  end;
end;


procedure RunOperation(const AConnection: TFxAdminConnection;
                       AAction: TFxAdminAction;
                       const AOriginalText: string;
                       const ANewText: string;
                       AResult: TFxAdminResult);
var
  Manager: SC_HANDLE;
  Service: SC_HANDLE;
  Access: DWORD;
  Connection: TFxAdminConnection;
  WasRunning: Boolean;
  Settings: TFxRecordSettings;

begin

  ValidateConnection(AConnection);
  Connection := AConnection;
  Access := SERVICE_QUERY_STATUS or SERVICE_QUERY_CONFIG;

  if AAction in [aaStart, aaRestart, aaApply] then
    Access := Access or SERVICE_START;

  if AAction in [aaStop, aaRestart, aaApply] then
    Access := Access or SERVICE_STOP;

  if (Connection.Machine = '.') then
    Manager := OpenSCManager(nil,
                             nil,
                             SC_MANAGER_CONNECT)
  else
    Manager := OpenSCManager(PChar(Connection.Machine),
                             nil,
                             SC_MANAGER_CONNECT);

  CheckResult((Manager <> 0),
              'Connect to Windows Service Control Manager');
  try
    Service := OpenService(Manager,
                           FX_RECORD_ADMIN_SERVICE,
                           Access);

    CheckResult((Service <> 0),
                'Open the FxRecord service');
    try
      Connection.ServerConfigFile := RegisteredConfigFile(Service);
      AResult.ServerConfigFile := Connection.ServerConfigFile;

      if not SameText(ExtractFileName(Connection.ConfigFile),
                      ExtractFileName(Connection.ServerConfigFile)) then
        raise Exception.Create('The shared INI filename differs from the INI registered for the service: ' +
                               Connection.ServerConfigFile);

      ReadServiceStatus(Service,
                        AResult);

      case AAction of
        aaConnect: AResult.ConfigText := ReadSharedText(Connection.ConfigFile,
                                                        False);
        aaStart: StartRecorder(Service,
                               AResult);

        aaStop: StopRecorder(Service,
                             AResult);

        aaRestart:
          begin
            StopRecorder(Service, AResult);
            StartRecorder(Service, AResult);
          end;

        aaSave, aaApply: begin
                           SettingsFromText(ANewText,
                                            Connection.ServerConfigFile,
                                            Settings);
                           ValidateSettings(Settings);

                           if (ReadSharedText(Connection.ConfigFile,
                                              False) <> AOriginalText) then
                             raise Exception.Create('The server INI changed since it was loaded. Reconnect before saving.');

                           if not (AResult.State in [SERVICE_RUNNING, SERVICE_STOPPED]) then
                             raise Exception.Create('Wait until the service is fully running or stopped before saving.');

                            WasRunning := (AResult.State = SERVICE_RUNNING);

                           if WasRunning and (AAction = aaSave) then
                             raise Exception.Create('Stop the service before saving, or use Save & restart.');

                           if WasRunning then StopRecorder(Service,
                                                           AResult);
                           try
                             ReplaceConfig(Connection,
                                           AOriginalText,
                                           ANewText,
                                           AResult);
                           except
                             // If saving failed, resume the previous working configuration.
                             if WasRunning and not AResult.ConfigSaved then
                               try
                                 StartRecorder(Service,
                                               AResult);
                               except
                                 on E: Exception do AResult.Notice := 'Could not restart the previous configuration: ' + E.Message;
                              end;
                              raise;
                           end;

            if WasRunning then
              StartRecorder(Service,
                            AResult);
          end;
      end;

      ReadServiceStatus(Service,
                        AResult);

      ReadRecorderFiles(Connection,
                        AResult);

    finally
      CloseServiceHandle(Service);
    end;

  finally
    CloseServiceHandle(Manager);
  end;
end;


constructor TFxAdminWorker.Create(AWindow: HWND;
                                  const AConnection: TFxAdminConnection;
                                  AAction: TFxAdminAction;
                                  const AOriginalText: string;
                                  const ANewText: string);
begin

  inherited Create(True);

  FreeOnTerminate := True;
  FWindow := AWindow;
  FConnection := AConnection;
  FAction := AAction;
  FOriginalText := AOriginalText;
  FNewText := ANewText;
end;


procedure TFxAdminWorker.Execute();
var
  ResultItem: TFxAdminResult;

begin

  ResultItem := TFxAdminResult.Create();
  ResultItem.Action := FAction;

  try
    RunOperation(FConnection,
                 FAction,
                 FOriginalText,
                 FNewText,
                 ResultItem);
  except
    on E: Exception do ResultItem.ErrorText := E.Message;
  end;

  if not PostMessage(FWindow,
                     FX_RECORD_ADMIN_RESULT,
                     0,
                     LPARAM(ResultItem)) then
    ResultItem.Free;
end;

// External

function ParseCommandLine; external Shell32Lib name 'CommandLineToArgvW';

end.