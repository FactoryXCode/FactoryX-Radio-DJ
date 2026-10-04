unit frmFxRecord;

interface

uses


  WinApi.Windows,
  WinApi.Messages,

  System.SysUtils,
  System.Classes,

  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Dialogs,

  FxRecord.Config,
  FxRecord.Monitor;

type
  TfrmFxRecord = class(TForm)
    PageControl: TPageControl;
    tabStatus: TTabSheet;
    tabRecorder: TTabSheet;
    memLog: TMemo;
    pnlStatusTop: TPanel;
    lblState: TLabel;
    btnStart: TButton;
    btnStop: TButton;
    btnClearLog: TButton;
    pnlBottom: TPanel;
    btnSave: TButton;
    btnClose: TButton;
    Panel1: TPanel;
    lblStreamPath: TLabel;
    lblArchivePath: TLabel;
    lblProfile: TLabel;
    lblSplitMinutes: TLabel;
    lblRetentionDays: TLabel;
    lblWarningGB: TLabel;
    lblCriticalGB: TLabel;
    edStreamPath: TEdit;
    btnBrowseStream: TButton;
    edArchivePath: TEdit;
    btnBrowseArchive: TButton;
    cbOutputProfile: TComboBox;
    edSplitMinutes: TEdit;
    edRetentionDays: TEdit;
    edWarningGB: TEdit;
    edCriticalGB: TEdit;
    chkRequireLive: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnBrowseStreamClick(Sender: TObject);
    procedure btnBrowseArchiveClick(Sender: TObject);
  private
    FConfigFileName: string;
    FSettings: TFxRecordSettings;
    FMonitor: TFxRecordMonitor;
    procedure AddLog(const AText: string);
    procedure LoadControls();
    function ReadControls(out AError: string): Boolean;
    procedure StartMonitor();
    procedure StopMonitor();
    procedure UpdateButtons();
    procedure SetRecorderControlsEnabled(const AEnabled: Boolean);
    procedure BrowseForFolder(AEdit: TEdit; const ACaption: string);
    procedure FxRecordNotice(var AMessage: TMessage); message WM_FXRECORD_NOTICE;
  public
  end;

var
  FxRecordForm: TfrmFxRecord;

implementation

{$R *.dfm}

uses
  LWFileBrowserExDlg;

procedure TfrmFxRecord.BrowseForFolder(AEdit: TEdit; const ACaption: string);
var
  Directory: string;
begin
  Directory := Trim(AEdit.Text);
  if BrowseLWFolderEx(Self, Directory, Directory, ACaption) then
    AEdit.Text := Directory;
end;

procedure TfrmFxRecord.btnBrowseStreamClick(Sender: TObject);
begin
  BrowseForFolder(edStreamPath, 'Select the stream folder');
end;

procedure TfrmFxRecord.btnBrowseArchiveClick(Sender: TObject);
begin
  BrowseForFolder(edArchivePath, 'Select or create the archive folder');
end;

procedure TfrmFxRecord.FormCreate(Sender: TObject);
begin
  FMonitor := nil;
  FConfigFileName := ChangeFileExt(ParamStr(0), '.ini');
  LoadFxRecordSettings(FConfigFileName, FSettings);
  { Starting FxRecord must never start monitoring before the administrator
    has had an opportunity to inspect the recorder settings. }
  FSettings.Enabled := False;
  LoadControls();
  AddLog('FxRecord is ready. Configuration: ' + FConfigFileName);
  AddLog('Recorder settings are ready. Press Start when configuration is complete.');
  { Explicit command-line startup is reserved for unattended/service testing.
    Normal desktop startup always waits for the administrator. }
  if FindCmdLineSwitch('start', ['-', '/'], True) then
    StartMonitor();
end;

procedure TfrmFxRecord.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  StopMonitor();
  CanClose := True;
end;

procedure TfrmFxRecord.AddLog(const AText: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);
  while memLog.Lines.Count > 1000 do
    memLog.Lines.Delete(0);
  memLog.SelStart := Length(memLog.Text);
end;

procedure TfrmFxRecord.LoadControls();
begin
  edStreamPath.Text := FSettings.StreamPath;
  edArchivePath.Text := FSettings.ArchivePath;
  cbOutputProfile.ItemIndex := cbOutputProfile.Items.IndexOf(FSettings.OutputProfile);
  if cbOutputProfile.ItemIndex < 0 then
    cbOutputProfile.ItemIndex := 0;
  edSplitMinutes.Text := IntToStr(FSettings.SplitMinutes);
  edRetentionDays.Text := IntToStr(FSettings.RetentionDays);
  edWarningGB.Text := IntToStr(FSettings.WarningFreeGB);
  edCriticalGB.Text := IntToStr(FSettings.CriticalFreeGB);
  chkRequireLive.Checked := FSettings.RequireLiveStream;
  UpdateButtons();
end;

function TfrmFxRecord.ReadControls(out AError: string): Boolean;
begin
  Result := False;
  AError := '';
  FSettings.StreamPath := Trim(edStreamPath.Text);
  FSettings.ArchivePath := Trim(edArchivePath.Text);
  FSettings.OutputProfile := cbOutputProfile.Text;
  FSettings.SplitMinutes := StrToIntDef(edSplitMinutes.Text, 0);
  FSettings.RetentionDays := StrToIntDef(edRetentionDays.Text, 0);
  FSettings.WarningFreeGB := StrToIntDef(edWarningGB.Text, 0);
  FSettings.CriticalFreeGB := StrToIntDef(edCriticalGB.Text, 0);
  FSettings.RequireLiveStream := chkRequireLive.Checked;

  if FSettings.StreamPath = '' then
    AError := 'Stream folder is required.'
  else if FSettings.ArchivePath = '' then
    AError := 'Archive folder is required.'
  else if FSettings.SplitMinutes <= 0 then
    AError := 'Split minutes must be greater than zero.'
  else if FSettings.RetentionDays <= 0 then
    AError := 'Retention days must be greater than zero.'
  else if (FSettings.CriticalFreeGB <= 0) or
          (FSettings.WarningFreeGB < FSettings.CriticalFreeGB) then
    AError := 'Disk warning must be greater than or equal to the critical value.';

  if AError <> '' then
    Exit;
  Result := AError = '';
end;

procedure TfrmFxRecord.StartMonitor();
var
  ErrorText: string;
begin
  if Assigned(FMonitor) then
    Exit;
  if not ReadControls(ErrorText) then
    begin
      ShowMessage(ErrorText);
      Exit;
    end;

  FSettings.Enabled := True;
  FMonitor := TFxRecordMonitor.Create(Handle, FSettings);
  FMonitor.Start();
  lblState.Caption := 'MONITORING';
  UpdateButtons();
end;

procedure TfrmFxRecord.StopMonitor();
begin
  if not Assigned(FMonitor) then
    Exit;
  FMonitor.Stop();
  FMonitor.WaitFor();
  FreeAndNil(FMonitor);
  lblState.Caption := 'STOPPED';
  UpdateButtons();
end;

procedure TfrmFxRecord.UpdateButtons();
var
  IsStopped: Boolean;
begin
  IsStopped := not Assigned(FMonitor);
  btnStart.Enabled := IsStopped;
  btnStop.Enabled := not IsStopped;
  btnSave.Enabled := IsStopped;
  SetRecorderControlsEnabled(IsStopped);
end;

procedure TfrmFxRecord.SetRecorderControlsEnabled(const AEnabled: Boolean);
var
  I: Integer;
begin
  for I := 0 to tabRecorder.ControlCount - 1 do
    tabRecorder.Controls[I].Enabled := AEnabled;
end;

procedure TfrmFxRecord.FxRecordNotice(var AMessage: TMessage);
var
  Item: PFxRecordNotice;
  Prefix: string;
begin
  Item := PFxRecordNotice(AMessage.LParam);
  if not Assigned(Item) then
    Exit;
  try
    case Item^.Level of
      fnWarning: Prefix := 'WARNING: ';
      fnCritical: Prefix := 'CRITICAL: ';
      fnRecovery: Prefix := 'RECOVERY: ';
    else
      Prefix := '';
    end;
    AddLog(Prefix + Item^.Text);
  finally
    Dispose(Item);
  end;
end;

procedure TfrmFxRecord.btnStartClick(Sender: TObject);
begin
  StartMonitor();
end;

procedure TfrmFxRecord.btnStopClick(Sender: TObject);
begin
  StopMonitor();
end;

procedure TfrmFxRecord.btnClearLogClick(Sender: TObject);
begin
  memLog.Clear();
end;

procedure TfrmFxRecord.btnSaveClick(Sender: TObject);
var
  ErrorText: string;
  WasRunning: Boolean;
begin
  if not ReadControls(ErrorText) then
    begin
      ShowMessage(ErrorText);
      Exit;
    end;
  WasRunning := Assigned(FMonitor);
  if WasRunning then
    StopMonitor();
  FSettings.Enabled := WasRunning;
  SaveFxRecordSettings(FConfigFileName, FSettings);
  AddLog('Configuration saved.');
  if WasRunning then
    StartMonitor();
end;

procedure TfrmFxRecord.btnCloseClick(Sender: TObject);
begin
  Close();
end;

end.
