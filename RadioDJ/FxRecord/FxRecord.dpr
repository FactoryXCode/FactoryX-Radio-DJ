program FxRecord;

uses
  Vcl.Forms,
  Winapi.Windows,
  System.SysUtils,
  System.Variants,
  System.IOUtils,
  Winapi.ActiveX,
  System.Win.ComObj,
  frmFxRecord in 'frmFxRecord.pas' {FxRecordForm},
  FxRecord.Config in 'FxRecord.Config.pas',
  FxRecord.Log in 'FxRecord.Log.pas',
  FxRecord.Recorder in 'FxRecord.Recorder.pas',
  FxRecord.Converter in 'FxRecord.Converter.pas',
  FxRecord.Service in 'FxRecord.Service.pas',
  FxRecord.Monitor in 'FxRecord.Monitor.pas';

{$R *.res}

function HasSwitch(const AValue: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if SameText(ParamStr(I), AValue) then
      Exit(True);
end;

function SwitchValue(const AName, ADefault: string): string;
var
  I: Integer;
begin
  Result := ADefault;
  for I := 1 to ParamCount - 1 do
    if SameText(ParamStr(I), AName) then
      Exit(ParamStr(I + 1));
end;

function RunWindowsUpdateCheck(): Integer;
var
  Session: OleVariant;
  Searcher: OleVariant;
  SearchResult: OleVariant;
begin
  Result := 20;
  CoInitialize(nil);
  try
    try
      Session := CreateOleObject('Microsoft.Update.Session');
      Searcher := Session.CreateUpdateSearcher;
      SearchResult := Searcher.Search('IsInstalled=0 and IsHidden=0');
      if SearchResult.Updates.Count > 0 then
        Result := 10
      else
        Result := 0;
    except
      on E: Exception do
        begin
          Result := 20;
          try
            TFile.WriteAllText(ChangeFileExt(ParamStr(0),
              '.update-check-error.log'), E.ClassName + ': ' + E.Message,
              TEncoding.UTF8);
          except
          end;
        end;
    end;
  finally
    SearchResult := Unassigned;
    Searcher := Unassigned;
    Session := Unassigned;
    CoUninitialize();
  end;
end;

var
  ConfigFileName: string;

begin
  if HasSwitch('--update-check') then
    begin
      ExitCode := RunWindowsUpdateCheck();
      Exit;
    end;
  ConfigFileName := ExpandFileName(SwitchValue('--config',
    ChangeFileExt(ParamStr(0), '.ini')));
  try
  if HasSwitch('--service') then
    RunFxRecordService(ConfigFileName)
  else if HasSwitch('--install') then
    InstallFxRecordService(ConfigFileName)
  else if HasSwitch('--uninstall') then
    UninstallFxRecordService()
  else
    begin
      Application.Initialize;
      Application.MainFormOnTaskbar := True;
      Application.Title := 'FactoryX FxRecord';
      Application.CreateForm(TfrmFxRecord, FxRecordForm);
      Application.Run;
    end;
  except
    on E: Exception do
    begin
      ExitCode := 1;
      AppendFxRecordLog(ConfigFileName, 'ERROR', E.ClassName + ': ' + E.Message);
      if not HasSwitch('--service') then
        MessageBox(0, PChar(E.Message + sLineBreak + 'Log: ' +
          ChangeFileExt(ConfigFileName, '.log')), 'FxRecord', MB_OK or MB_ICONERROR);
    end;
  end;
end.
