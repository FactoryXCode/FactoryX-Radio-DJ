// FactoryX
//
// Copyright (c) FactoryX, Netherlands/Australia/Germany. All rights reserved.
//
// Project: Media Foundation - MFPack - Samples
// Project location: https://sourceforge.net/projects/MFPack
//                   https://github.com/FactoryXCode/MfPack
// Module: FxRecord.Service.pas
// Kind: Pascal Unit
// Release date: 10-08-2026
// Language: ENU
//
// Revision Version: 4.0.0
// Description: Runs, installs and removes the FxRecord Windows service.
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
unit FxRecord.Service;

interface

uses

  {WinApi}
  WinApi.Windows,
  WinApi.WinSvc,
  {System}
  System.SysUtils;

const
  FX_RECORD_SERVICE_NAME = 'FxRecord';
  FX_RECORD_DISPLAY_NAME = 'FxRecord';

  procedure RunFxRecordService(const AConfigFileName: string);
  procedure InstallFxRecordService(const AConfigFileName: string);
  procedure UninstallFxRecordService();


implementation

uses
  {Application}
  FxRecord.Log,
  FxRecord.Config,
  FxRecord.Monitor;

var
  GConfigFileName: string;
  GStatusHandle: SERVICE_STATUS_HANDLE;
  GStatus: TServiceStatus;
  GStopEvent: THandle;
  GCheckPoint: DWORD;


procedure CheckServiceCall(const ASucceeded: Boolean; const AOperation: string);
var
  ErrorCode: DWORD;
begin
  if ASucceeded then Exit;
  ErrorCode := GetLastError();
  raise EOSError.CreateFmt('%s failed (Windows error %d): %s',
                           [AOperation, ErrorCode, SysErrorMessage(ErrorCode)]);
end;

procedure ReportServiceStatus(const AState,
                                    AWin32ExitCode,
                                    AWaitHint: DWORD);
begin

  GStatus.dwCurrentState := AState;
  GStatus.dwWin32ExitCode := AWin32ExitCode;
  GStatus.dwWaitHint := AWaitHint;

  if (AState = SERVICE_START_PENDING) then
    GStatus.dwControlsAccepted := 0
  else
    GStatus.dwControlsAccepted := SERVICE_ACCEPT_STOP or SERVICE_ACCEPT_SHUTDOWN;

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

  SetServiceStatus(GStatusHandle,
                   GStatus);
end;


procedure ServiceControlHandler(const AControl: DWORD); stdcall;
begin

  case AControl of
    SERVICE_CONTROL_STOP,
    SERVICE_CONTROL_SHUTDOWN: if (GStatus.dwCurrentState = SERVICE_RUNNING) then
                                begin
                                  ReportServiceStatus(SERVICE_STOP_PENDING,
                                  NO_ERROR,
                                  30000);

                                  if (GStopEvent <> 0) then
                                    SetEvent(GStopEvent);

                                end;

    SERVICE_CONTROL_INTERROGATE: SetServiceStatus(GStatusHandle,
                                                  GStatus);
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

  FillChar(GStatus,
           SizeOf(GStatus),
           0);

  GStatus.dwServiceType := SERVICE_WIN32_OWN_PROCESS;
  GStatusHandle := RegisterServiceCtrlHandler(FX_RECORD_SERVICE_NAME,
                                               @ServiceControlHandler);
  if (GStatusHandle = 0) then
    begin
      AppendFxRecordLog(GConfigFileName, 'ERROR',
        'RegisterServiceCtrlHandler failed: ' + SysErrorMessage(GetLastError()));
      Exit;
    end;

  GStopEvent := CreateEvent(nil,
                            True,
                            False,
                            nil);

  if (GStopEvent = 0) then
    begin
      ReportServiceStatus(SERVICE_STOPPED,
                          GetLastError(),
                          0);
      Exit;
    end;

  AppendFxRecordLog(GConfigFileName, 'INFO', 'Service starting. Configuration: ' + GConfigFileName);
  Monitor := nil;
  ExitCode := NO_ERROR;

  try
    ReportServiceStatus(SERVICE_START_PENDING,
                        NO_ERROR,
                        30000);

   try
      if not FileExists(GConfigFileName) then
        raise Exception.Create('Configuration file not found: ' + GConfigFileName);
      if not AppendFxRecordLog(GConfigFileName, 'INFO', 'Loading service configuration.') then
        raise Exception.Create('Cannot write service log: ' + ChangeFileExt(GConfigFileName, '.log'));
      LoadFxRecordSettings(GConfigFileName,
                           Settings);

      Settings.Enabled := True;
      LogFileName := ChangeFileExt(GConfigFileName,
                                   '.log');

      Monitor := TFxRecordMonitor.Create(0,
                                         Settings,
                                         LogFileName);
      Monitor.Start();

      ReportServiceStatus(SERVICE_RUNNING,
                          NO_ERROR,
                          0);

      WaitForSingleObject(GStopEvent,
                          INFINITE);

      ReportServiceStatus(SERVICE_STOP_PENDING,
                          NO_ERROR,
                          30000);
      Monitor.Stop();

      while (WaitForSingleObject(Monitor.Handle,
                                 1000) = WAIT_TIMEOUT) do
        ReportServiceStatus(SERVICE_STOP_PENDING,
                            NO_ERROR,
                            30000);

      Monitor.WaitFor();

    except

      on E: Exception do
        begin
          AppendFxRecordLog(GConfigFileName, 'ERROR', E.ClassName + ': ' + E.Message);
          OutputDebugString(PChar('FxRecord service error: ' + E.Message));
          ExitCode := ERROR_SERVICE_SPECIFIC_ERROR;
          GStatus.dwServiceSpecificExitCode := 1;
        end;
    end;

  finally
    Monitor.Free();
    CloseHandle(GStopEvent);
    GStopEvent := 0;
    ReportServiceStatus(SERVICE_STOPPED,
                        ExitCode,
                        0);
  end;
end;


procedure RunFxRecordService(const AConfigFileName: string);
var
  ServiceTable: array[0..1] of TServiceTableEntry;

begin

  GConfigFileName := ExpandFileName(AConfigFileName);

  FillChar(ServiceTable,
           SizeOf(ServiceTable),
           0);

  ServiceTable[0].lpServiceName := PChar(FX_RECORD_SERVICE_NAME);
  ServiceTable[0].lpServiceProc := @FxRecordServiceMain;

  CheckServiceCall(StartServiceCtrlDispatcher(ServiceTable[0]),
    'StartServiceCtrlDispatcher (start the installed service through Services or sc.exe)');
end;


function ServiceBinaryCommand(const AConfigFileName: string): string;
begin

  Result := '"' + ExpandFileName(ParamStr(0)) + '" --service --config "' + ExpandFileName(AConfigFileName) + '"';
end;


procedure ConfigureServiceResilience(const AService: SC_HANDLE;
                                     const AConfigFileName: string);
var
  DelayedInfo: SERVICE_DELAYED_AUTO_START_INFO;
  FailureFlag: SERVICE_FAILURE_ACTIONS_FLAG;
  Actions: array[0..2] of SC_ACTION;
  FailureActions: SERVICE_FAILURE_ACTIONS;
  ErrorCode: DWORD;

begin

  FillChar(DelayedInfo, SizeOf(DelayedInfo), 0);
  FillChar(FailureFlag, SizeOf(FailureFlag), 0);
  FillChar(Actions, SizeOf(Actions), 0);
  // Delphi LongBool True is -1. SCM validates these flags as Windows TRUE (1).
  PLongInt(@DelayedInfo.fDelayedAutostart)^ := 1;

  if not ChangeServiceConfig2(AService,
                              SERVICE_CONFIG_DELAYED_AUTO_START_INFO,
                              @DelayedInfo) then
    begin
      ErrorCode := GetLastError();
      AppendFxRecordLog(AConfigFileName, 'WARNING',
        Format('Delayed automatic startup was not configured (Windows error %d): %s. ' +
          'Service remains configured for automatic startup.',
          [ErrorCode, SysErrorMessage(ErrorCode)]));
    end
  else
    AppendFxRecordLog(AConfigFileName, 'INFO', 'Delayed automatic startup configured.');

  Actions[0].&Type := SC_ACTION_RESTART;
  Actions[0].Delay := 60000;
  Actions[1].&Type := SC_ACTION_RESTART;
  Actions[1].Delay := 60000;
  Actions[2].&Type := SC_ACTION_RESTART;
  Actions[2].Delay := 60000;

  FillChar(FailureActions,
           SizeOf(FailureActions),
           0);

  FailureActions.dwResetPeriod := 86400;
  FailureActions.cActions := Length(Actions);
  FailureActions.lpsaActions := @Actions[0];

  CheckServiceCall(ChangeServiceConfig2(AService,
                              SERVICE_CONFIG_FAILURE_ACTIONS,
                              @FailureActions), 'Configure service restart actions');

  PLongInt(@FailureFlag.fFailureActionsOnNonCrashFailures)^ := 1;

  CheckServiceCall(ChangeServiceConfig2(AService,
                              SERVICE_CONFIG_FAILURE_ACTIONS_FLAG,
                              @FailureFlag), 'Configure failure recovery flag');
end;


procedure InstallFxRecordService(const AConfigFileName: string);
var
  Manager: SC_HANDLE;
  Service: SC_HANDLE;
  CommandLine: string;
  Status: TServiceStatus;
  ErrorCode: DWORD;

begin

  if (Copy(ExpandFileName(ParamStr(0)), 1, 2) = #92#92) or
     (Copy(ExpandFileName(AConfigFileName), 1, 2) = #92#92) then
    raise Exception.Create('Install FxRecord on the server using its local drive paths, ' +
      'not a UNC share path. Use the share path only in FxRecordAdmin.');
  if not FileExists(AConfigFileName) then
    raise Exception.CreateFmt('Configuration file not found: %s',
                              [ExpandFileName(AConfigFileName)]);

  Manager := OpenSCManager(nil,
                           nil,
                           SC_MANAGER_CONNECT or SC_MANAGER_CREATE_SERVICE);

  CheckServiceCall(Manager <> 0, 'Open local Service Control Manager');
  try
    CommandLine := ServiceBinaryCommand(AConfigFileName);
    AppendFxRecordLog(AConfigFileName, 'INFO', 'Installing service: ' + CommandLine);

    Service := CreateService(Manager,
                             FX_RECORD_SERVICE_NAME,
                             FX_RECORD_DISPLAY_NAME,
                             SERVICE_ALL_ACCESS,
                             SERVICE_WIN32_OWN_PROCESS,
                             SERVICE_AUTO_START,
                             SERVICE_ERROR_NORMAL,
                             PChar(CommandLine),
                             nil,
                             nil,
                             nil,
                             nil,
                             nil);

    if Service = 0 then
    begin
      ErrorCode := GetLastError();
      if ErrorCode <> ERROR_SERVICE_EXISTS then
        raise EOSError.CreateFmt('Create FxRecord service failed (Windows error %d): %s',
          [ErrorCode, SysErrorMessage(ErrorCode)]);
      Service := OpenService(Manager, FX_RECORD_SERVICE_NAME,
        SERVICE_QUERY_STATUS or SERVICE_CHANGE_CONFIG or SERVICE_START);
      CheckServiceCall(Service <> 0, 'Open existing FxRecord service');
      try
        CheckServiceCall(QueryServiceStatus(Service, Status), 'Query existing FxRecord service');
        if Status.dwCurrentState <> SERVICE_STOPPED then
          raise Exception.Create('Stop the FxRecord service before repairing its installation.');
        CheckServiceCall(ChangeServiceConfig(Service, SERVICE_NO_CHANGE,
          SERVICE_AUTO_START, SERVICE_NO_CHANGE, PChar(CommandLine), nil,
          nil, nil, nil, nil, FX_RECORD_DISPLAY_NAME), 'Update FxRecord service command');
      except
        CloseServiceHandle(Service);
        raise;
      end;
    end;

    try
      ConfigureServiceResilience(Service, AConfigFileName);
      AppendFxRecordLog(AConfigFileName, 'INFO', 'Service installation completed.');
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

  Manager := OpenSCManager(nil,
                           nil,
                           SC_MANAGER_CONNECT);

  CheckServiceCall(Manager <> 0, 'Open local Service Control Manager');

  try
    Service := OpenService(Manager,
                           FX_RECORD_SERVICE_NAME,
                           $00010000 or SERVICE_STOP or SERVICE_QUERY_STATUS);
    CheckServiceCall(Service <> 0, 'Create/open FxRecord service');
    try
      if QueryServiceStatus(Service,
                            Status) and (Status.dwCurrentState <> SERVICE_STOPPED) then
        begin
          ControlService(Service,
                         SERVICE_CONTROL_STOP,
                         Status);
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
