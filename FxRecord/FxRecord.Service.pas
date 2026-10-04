unit FxRecord.Service;

interface

uses
  Winapi.Windows,
  Winapi.WinSvc,
  System.SysUtils;

const
  FX_RECORD_SERVICE_NAME = 'FxRecord';
  FX_RECORD_DISPLAY_NAME = 'FactoryX FxRecord';

procedure RunFxRecordService(const AConfigFileName: string);
procedure InstallFxRecordService(const AConfigFileName: string);
procedure UninstallFxRecordService();

implementation

uses
  FxRecord.Config,
  FxRecord.Monitor;

var
  GConfigFileName: string;
  GStatusHandle: SERVICE_STATUS_HANDLE;
  GStatus: TServiceStatus;
  GStopEvent: THandle;
  GCheckPoint: DWORD;

procedure ReportServiceStatus(const AState,
                                    AWin32ExitCode,
                                    AWaitHint: DWORD);
begin
  GStatus.dwCurrentState := AState;
  GStatus.dwWin32ExitCode := AWin32ExitCode;
  GStatus.dwWaitHint := AWaitHint;
  if AState = SERVICE_START_PENDING then
    GStatus.dwControlsAccepted := 0
  else
    GStatus.dwControlsAccepted := SERVICE_ACCEPT_STOP or
                                  SERVICE_ACCEPT_SHUTDOWN;
  if (AState = SERVICE_RUNNING) or (AState = SERVICE_STOPPED) then
    begin
      GCheckPoint := 0;
      GStatus.dwCheckPoint := 0;
    end
  else
    begin
      Inc(GCheckPoint);
      GStatus.dwCheckPoint := GCheckPoint;
    end;
  SetServiceStatus(GStatusHandle, GStatus);
end;

procedure ServiceControlHandler(const AControl: DWORD); stdcall;
begin
  case AControl of
    SERVICE_CONTROL_STOP,
    SERVICE_CONTROL_SHUTDOWN:
      if GStatus.dwCurrentState = SERVICE_RUNNING then
        begin
          ReportServiceStatus(SERVICE_STOP_PENDING, NO_ERROR, 30000);
          if GStopEvent <> 0 then
            SetEvent(GStopEvent);
        end;
    SERVICE_CONTROL_INTERROGATE:
      SetServiceStatus(GStatusHandle, GStatus);
  end;
end;

procedure FxRecordServiceMain(AArgCount: DWORD;
                              AArgVectors: PLPWSTR); stdcall;
var
  Settings: TFxRecordSettings;
  Monitor: TFxRecordMonitor;
  ExitCode: DWORD;
  LogFileName: string;
begin
  FillChar(GStatus, SizeOf(GStatus), 0);
  GStatus.dwServiceType := SERVICE_WIN32_OWN_PROCESS;
  GStatusHandle := RegisterServiceCtrlHandler(FX_RECORD_SERVICE_NAME,
                                               @ServiceControlHandler);
  if GStatusHandle = 0 then
    Exit;
  GStopEvent := CreateEvent(nil, True, False, nil);
  if GStopEvent = 0 then
    begin
      ReportServiceStatus(SERVICE_STOPPED, GetLastError(), 0);
      Exit;
    end;

  Monitor := nil;
  ExitCode := NO_ERROR;
  try
    ReportServiceStatus(SERVICE_START_PENDING, NO_ERROR, 30000);
    try
      LoadFxRecordSettings(GConfigFileName, Settings);
      Settings.Enabled := True;
      LogFileName := ChangeFileExt(GConfigFileName, '.log');
      Monitor := TFxRecordMonitor.Create(0, Settings, LogFileName);
      Monitor.Start();
      ReportServiceStatus(SERVICE_RUNNING, NO_ERROR, 0);
      WaitForSingleObject(GStopEvent, INFINITE);
      ReportServiceStatus(SERVICE_STOP_PENDING, NO_ERROR, 30000);
      Monitor.Stop();
      while WaitForSingleObject(Monitor.Handle, 1000) = WAIT_TIMEOUT do
        ReportServiceStatus(SERVICE_STOP_PENDING, NO_ERROR, 30000);
      Monitor.WaitFor();
    except
      on E: Exception do
        begin
          OutputDebugString(PChar('FxRecord service error: ' + E.Message));
          ExitCode := ERROR_SERVICE_SPECIFIC_ERROR;
          GStatus.dwServiceSpecificExitCode := 1;
        end;
    end;
  finally
    Monitor.Free();
    CloseHandle(GStopEvent);
    GStopEvent := 0;
    ReportServiceStatus(SERVICE_STOPPED, ExitCode, 0);
  end;
end;

procedure RunFxRecordService(const AConfigFileName: string);
var
  ServiceTable: array[0..1] of TServiceTableEntry;
begin
  GConfigFileName := ExpandFileName(AConfigFileName);
  FillChar(ServiceTable, SizeOf(ServiceTable), 0);
  ServiceTable[0].lpServiceName := PChar(FX_RECORD_SERVICE_NAME);
  ServiceTable[0].lpServiceProc := @FxRecordServiceMain;
  if not StartServiceCtrlDispatcher(ServiceTable[0]) then
    raise EOSError.CreateFmt('StartServiceCtrlDispatcher failed: %s',
                             [SysErrorMessage(GetLastError())]);
end;

function ServiceBinaryCommand(const AConfigFileName: string): string;
begin
  Result := '"' + ExpandFileName(ParamStr(0)) +
            '" --service --config "' +
            ExpandFileName(AConfigFileName) + '"';
end;

procedure ConfigureServiceResilience(const AService: SC_HANDLE);
var
  DelayedInfo: SERVICE_DELAYED_AUTO_START_INFO;
  FailureFlag: SERVICE_FAILURE_ACTIONS_FLAG;
  Actions: array[0..2] of SC_ACTION;
  FailureActions: SERVICE_FAILURE_ACTIONS;
begin
  DelayedInfo.fDelayedAutostart := True;
  if not ChangeServiceConfig2(AService,
                              SERVICE_CONFIG_DELAYED_AUTO_START_INFO,
                              @DelayedInfo) then
    RaiseLastOSError();
  Actions[0].&Type := SC_ACTION_RESTART;
  Actions[0].Delay := 60000;
  Actions[1].&Type := SC_ACTION_RESTART;
  Actions[1].Delay := 60000;
  Actions[2].&Type := SC_ACTION_RESTART;
  Actions[2].Delay := 60000;
  FillChar(FailureActions, SizeOf(FailureActions), 0);
  FailureActions.dwResetPeriod := 86400;
  FailureActions.cActions := Length(Actions);
  FailureActions.lpsaActions := @Actions[0];
  if not ChangeServiceConfig2(AService,
                              SERVICE_CONFIG_FAILURE_ACTIONS,
                              @FailureActions) then
    RaiseLastOSError();
  FailureFlag.fFailureActionsOnNonCrashFailures := True;
  if not ChangeServiceConfig2(AService,
                              SERVICE_CONFIG_FAILURE_ACTIONS_FLAG,
                              @FailureFlag) then
    RaiseLastOSError();
end;

procedure InstallFxRecordService(const AConfigFileName: string);
var
  Manager: SC_HANDLE;
  Service: SC_HANDLE;
  CommandLine: string;
begin
  if not FileExists(AConfigFileName) then
    raise Exception.CreateFmt('Configuration file not found: %s',
                              [ExpandFileName(AConfigFileName)]);
  Manager := OpenSCManager(nil, nil, SC_MANAGER_CREATE_SERVICE);
  if Manager = 0 then
    RaiseLastOSError();
  try
    CommandLine := ServiceBinaryCommand(AConfigFileName);
    Service := CreateService(Manager,
                             FX_RECORD_SERVICE_NAME,
                             FX_RECORD_DISPLAY_NAME,
                             SERVICE_ALL_ACCESS,
                             SERVICE_WIN32_OWN_PROCESS,
                             SERVICE_AUTO_START,
                             SERVICE_ERROR_NORMAL,
                             PChar(CommandLine),
                             nil, nil, nil, nil, nil);
    if Service = 0 then
      RaiseLastOSError();
    try
      ConfigureServiceResilience(Service);
    finally
      CloseServiceHandle(Service);
    end;
  finally
    CloseServiceHandle(Manager);
  end;
end;

procedure UninstallFxRecordService();
var
  Manager: SC_HANDLE;
  Service: SC_HANDLE;
  Status: TServiceStatus;
begin
  Manager := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if Manager = 0 then
    RaiseLastOSError();
  try
    Service := OpenService(Manager, FX_RECORD_SERVICE_NAME,
                           $00010000 or SERVICE_STOP or SERVICE_QUERY_STATUS);
    if Service = 0 then
      RaiseLastOSError();
    try
      if QueryServiceStatus(Service, Status) and
         (Status.dwCurrentState <> SERVICE_STOPPED) then
        begin
          ControlService(Service, SERVICE_CONTROL_STOP, Status);
          Sleep(500);
        end;
      if not DeleteService(Service) then
        RaiseLastOSError();
    finally
      CloseServiceHandle(Service);
    end;
  finally
    CloseServiceHandle(Manager);
  end;
end;

end.
