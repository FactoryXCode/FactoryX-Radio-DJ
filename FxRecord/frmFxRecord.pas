// FactoryX
//
// Copyright (c) FactoryX, Netherlands/Australia/Germany. All rights reserved.
//
// Project: Media Foundation - MFPack - Samples
// Project location: https://sourceforge.net/projects/MFPack
//                   https://github.com/FactoryXCode/MfPack
// Module: frmFxRecord.pas
// Kind: Pascal Unit
// Release date: 10-08-2026
// Language: ENU
//
// Revision Version: 4.0.0
// Description: Recorder configuration and monitoring user interface.
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
unit frmFxRecord;

interface

uses

  {WinApi}
  WinApi.Windows,
  WinApi.Messages,
  {System}
  System.SysUtils,
  System.Classes,
  {Vcl}
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Dialogs,
  {Application}
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
    btnOpenArchive: TButton;
    pnlBottom: TPanel;
    btnSave: TButton;
    btnClose: TButton;
    Panel1: TPanel;
    lblStreamPath: TLabel;
    lblArchivePath: TLabel;
    lblProfile: TLabel;
    lblFragmentduration: TLabel;
    lblRetentionDays: TLabel;
    lblWarningGB: TLabel;
    lblCriticalGB: TLabel;
    edStreamPath: TEdit;
    btnBrowseStream: TButton;
    edArchivePath: TEdit;
    btnBrowseArchive: TButton;
    cbOutputProfile: TComboBox;
    edFragmentduration: TEdit;
    edRetentionDays: TEdit;
    edWarningGB: TEdit;
    edCriticalGB: TEdit;
    chkRequireLive: TCheckBox;
    lblPollingInterval: TLabel;
    edPollingInterval: TEdit;
    lblMp3Rate: TLabel;
    lblMp3BitRate: TLabel;
    cbMp3Rate: TComboBox;
    cbMp3BitRate: TComboBox;
    lblAacRate: TLabel;
    lblAacBitRate: TLabel;
    cbAacRate: TComboBox;
    cbAacBitRate: TComboBox;
    lblAacLimits: TLabel;
    Bevel1: TBevel;
    Label1: TLabel;

    procedure cbOutputProfileChange(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnOpenArchiveClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnBrowseStreamClick(Sender: TObject);
    procedure btnBrowseArchiveClick(Sender: TObject);
    procedure edStreamPathChange(Sender: TObject);
    procedure edArchivePathChange(Sender: TObject);

  private
    FConfigFileName: string;
    FSettings: TFxRecordSettings;
    FMonitor: TFxRecordMonitor;

    procedure AddLog(const AText: string);
    procedure GetSettings();
    function SetSettings(out AError: string): Boolean;
    procedure StartMonitor();
    procedure StopMonitor();
    procedure UpdateButtons();
    procedure UpdateAudioControls();
    procedure SetRecorderControlsEnabled(const AEnabled: Boolean);
    procedure BrowseForFolder(AEdit: TEdit; const ACaption: string);
    procedure FxRecordNotice(var AMessage: TMessage); message WM_FXRECORD_NOTICE;

  end;

var
  FxRecordForm: TfrmFxRecord;


implementation

{$R *.dfm}

uses

  {WinApi}
  WinApi.ShellApi,
  {Application}
  FxRecord.Log,
  LWFileBrowserExDlg;


procedure TfrmFxRecord.BrowseForFolder(AEdit: TEdit;
                                       const ACaption: string);
var
  Directory: string;

begin

  Directory := Trim(AEdit.Text);

  if BrowseLWFolderEx(Self,
                      Directory,
                      Directory,
                      ACaption) then
    AEdit.Text := Directory;
end;


procedure TfrmFxRecord.btnBrowseStreamClick(Sender: TObject);
begin

  BrowseForFolder(edStreamPath,
                  'Select the stream folder');
end;


procedure TfrmFxRecord.btnBrowseArchiveClick(Sender: TObject);
begin

  BrowseForFolder(edArchivePath,
                  'Select or create the archive folder');
end;


procedure TfrmFxRecord.FormCreate(Sender: TObject);
var
  I: Integer;
begin

  FMonitor := nil;
  FConfigFileName := ChangeFileExt(ParamStr(0),
                                   '.ini');
  for I := 1 to ParamCount - 1 do
    if SameText(ParamStr(I), '--config') then
      FConfigFileName := ExpandFileName(ParamStr(I + 1));

  LoadFxRecordSettings(FConfigFileName,
                       FSettings);

  // Starting FxRecord must never start monitoring before the administrator
  // has had an opportunity to inspect the recorder settings.
  FSettings.Enabled := False;
  GetSettings();

  if not AppendFxRecordLog(FConfigFileName, 'INFO', 'Desktop application started.') then
    ShowMessage('Cannot write ' + ChangeFileExt(FConfigFileName, '.log') +
      '. Grant this Windows account write access to the configuration folder.');
  AddLog('FxRecord is ready. Configuration: ' + FConfigFileName);
  AddLog('Recorder settings are ready. Press Start when configuration is complete.');

  // Explicit command-line startup is reserved for unattended/service testing.
  //  Normal desktop startup always waits for the administrator.
  if FindCmdLineSwitch('start',
                       ['-', '/'],
                       True) then
    StartMonitor();
end;


procedure TfrmFxRecord.FormCloseQuery(Sender: TObject;
                                      var CanClose: Boolean);
begin

  StopMonitor();
  CanClose := True;
end;


procedure TfrmFxRecord.AddLog(const AText: string);
begin

  AppendFxRecordLog(FConfigFileName, 'INFO', AText);
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);

  while (memLog.Lines.Count > 1000) do
    memLog.Lines.Delete(0);

  memLog.SelStart := Length(memLog.Text);
end;


procedure TfrmFxRecord.GetSettings();
begin

  edStreamPath.Text := FSettings.StreamPath;
  edArchivePath.Text := FSettings.ArchivePath;
  cbOutputProfile.ItemIndex := cbOutputProfile.Items.IndexOf(FSettings.OutputProfile);

  if (cbOutputProfile.ItemIndex < 0) then
    cbOutputProfile.ItemIndex := 0;

  edFragmentDuration.Text := IntToStr(FSettings.FragmentDuration);
  edRetentionDays.Text := IntToStr(FSettings.RetentionDays);
  edWarningGB.Text := IntToStr(FSettings.WarningFreeGB);
  edCriticalGB.Text := IntToStr(FSettings.CriticalFreeGB);
  chkRequireLive.Checked := FSettings.RequireLiveStream;
  edPollingInterval.Text := IntToStr(FSettings.PollIntervalMs);

  case FSettings.Mp3SampleRate of
    48000: cbMp3Rate.ItemIndex := 1;
    32000: cbMp3Rate.ItemIndex := 2;
  else
    cbMp3Rate.ItemIndex := 0;
  end;

  cbMp3BitRate.ItemIndex := cbMp3BitRate.Items.IndexOf(IntToStr(FSettings.Mp3BitRateKbps));

  if (cbMp3BitRate.ItemIndex < 0) then
    cbMp3BitRate.ItemIndex := 2;

  if (FSettings.AacSampleRate = 48000) then
    cbAacRate.ItemIndex := 1
  else
    cbAacRate.ItemIndex := 0;

  cbAacBitRate.ItemIndex := cbAacBitRate.Items.IndexOf(IntToStr(FSettings.AacBitRateKbps));

  if (cbAacBitRate.ItemIndex < 0) then
    cbAacBitRate.ItemIndex := 2;

  UpdateButtons();
end;


function TfrmFxRecord.SetSettings(out AError: string): Boolean;
begin

  Result := False;
  AError := '';
  FSettings.StreamPath := Trim(edStreamPath.Text);
  FSettings.ArchivePath := Trim(edArchivePath.Text);
  FSettings.OutputProfile := cbOutputProfile.Text;

  case cbMp3Rate.ItemIndex of
    0: FSettings.Mp3SampleRate := 44100;
    1: FSettings.Mp3SampleRate := 48000;
    2: FSettings.Mp3SampleRate := 32000;
  else
    FSettings.Mp3SampleRate := 0;
  end;

  if (cbAacRate.ItemIndex = 0) then
    FSettings.AacSampleRate := 44100
  else
    if (cbAacRate.ItemIndex = 1) then
      FSettings.AacSampleRate := 48000
    else
      FSettings.AacSampleRate := 0;

  FSettings.Mp3BitRateKbps := StrToIntDef(cbMp3BitRate.Text,
                                          0);
  FSettings.AacBitRateKbps := StrToIntDef(cbAacBitRate.Text,
                                          0);

  if SameText(FSettings.OutputProfile,
              'AVI-H264-MP3') and ((FSettings.Mp3SampleRate = 0) or (cbMp3BitRate.ItemIndex < 0)) then
  begin
    AError := 'Select an MP3 sample rate and bitrate.';
    Exit;
  end;

  if SameText(FSettings.OutputProfile,
              'MP4-H264-AAC') and ((FSettings.AacSampleRate = 0) or (cbAacBitRate.ItemIndex < 0)) then
  begin
    AError := 'Select an AAC sample rate and bitrate (96-192 kbps).';
    Exit;
  end;

  FSettings.FragmentDuration := StrToIntDef(edFragmentDuration.Text,
                                            0);

  FSettings.RetentionDays := StrToIntDef(edRetentionDays.Text,
                                         0);

  FSettings.WarningFreeGB := StrToIntDef(edWarningGB.Text,
                                         0);

  FSettings.CriticalFreeGB := StrToIntDef(edCriticalGB.Text,
                                          0);

  FSettings.PollIntervalMs := StrToIntDef(edPollingInterval.Text,
                                          0);

  FSettings.RequireLiveStream := chkRequireLive.Checked;

  if (FSettings.StreamPath = '') then
    AError := 'Stream folder is required.'
  else
    if (FSettings.ArchivePath = '') then
      AError := 'Archive folder is required.'
    else
      if (FSettings.FragmentDuration <= 0) then
        AError := 'Fragment duration must be greater than zero.'
      else
        if (FSettings.RetentionDays <= 0) then
          AError := 'Retention days must be greater than zero.'
        else
          if (FSettings.CriticalFreeGB <= 0) or (FSettings.WarningFreeGB < FSettings.CriticalFreeGB) then
            AError := 'Disk warning must be greater than or equal to the critical value.'
          else
            if not SameText(FSettings.OutputProfile,
                            'SourceCopy') and
               not SameText(FSettings.OutputProfile,
                            'MP4-H264-AAC') and
               not SameText(FSettings.OutputProfile,
                            'AVI-H264-MP3') then
              AError := 'This output profile is not implemented yet.';

  if (AError <> '') then
    Exit;

  Result := AError = '';
end;


procedure TfrmFxRecord.StartMonitor();
var
  ErrorText: string;

begin

  if Assigned(FMonitor) then
    Exit;

  if not SetSettings(ErrorText) then
    begin
      ShowMessage(ErrorText);
      Exit;
    end;

  FSettings.Enabled := True;
  FMonitor := TFxRecordMonitor.Create(Handle,
                                      FSettings);
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
  UpdateAudioControls();
end;


procedure TfrmFxRecord.cbOutputProfileChange(Sender: TObject);
begin

  UpdateAudioControls();
end;


procedure TfrmFxRecord.UpdateAudioControls();
var
  Mp3Enabled: Boolean;
  AacEnabled: Boolean;

begin

  Mp3Enabled := not Assigned(FMonitor) and SameText(cbOutputProfile.Text,
                                                    'AVI-H264-MP3');
  AacEnabled := not Assigned(FMonitor) and SameText(cbOutputProfile.Text,
                                                    'MP4-H264-AAC');

  cbMp3Rate.Enabled := Mp3Enabled;
  cbMp3BitRate.Enabled := Mp3Enabled;
  lblMp3Rate.Enabled := Mp3Enabled;
  lblMp3BitRate.Enabled := Mp3Enabled;
  cbAacRate.Enabled := AacEnabled;
  cbAacBitRate.Enabled := AacEnabled;
  lblAacRate.Enabled := AacEnabled;
  lblAacBitRate.Enabled := AacEnabled;
  lblAacLimits.Enabled := AacEnabled;
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


procedure TfrmFxRecord.edStreamPathChange(Sender: TObject);
begin

  FSettings.StreamPath := Trim(edStreamPath.Text);
end;


procedure TfrmFxRecord.edArchivePathChange(Sender: TObject);
begin

  FSettings.ArchivePath := Trim(edArchivePath.Text);
end;


procedure TfrmFxRecord.btnClearLogClick(Sender: TObject);
begin

  memLog.Clear();
end;


procedure TfrmFxRecord.btnOpenArchiveClick(Sender: TObject);
begin

  if not DirectoryExists(FSettings.ArchivePath) and not ForceDirectories(FSettings.ArchivePath) then
    begin
      ShowMessage('The archive folder cannot be created:' + sLineBreak + FSettings.ArchivePath);
      Exit;
    end;

  if (ShellExecute(Handle,
                   'open',
                   PChar(FSettings.ArchivePath),
                   nil,
                   nil,
                   SW_SHOWNORMAL) <= 32) then
    ShowMessage('Windows Explorer could not open:' + sLineBreak + FSettings.ArchivePath);
end;


procedure TfrmFxRecord.btnSaveClick(Sender: TObject);
var
  ErrorText: string;
  WasRunning: Boolean;

begin

  if not SetSettings(ErrorText) then
    begin
      ShowMessage(ErrorText);
      Exit;
    end;

  WasRunning := Assigned(FMonitor);
  if WasRunning then
    StopMonitor();

  FSettings.Enabled := WasRunning;
  SaveFxRecordSettings(FConfigFileName,
                       FSettings);

  AddLog('Configuration saved.');

  if WasRunning then
    StartMonitor();
end;


procedure TfrmFxRecord.btnCloseClick(Sender: TObject);
begin

  Close();
end;

end.
