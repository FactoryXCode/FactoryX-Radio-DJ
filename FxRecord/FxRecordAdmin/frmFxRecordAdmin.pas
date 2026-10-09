// FactoryX
//
// Copyright (c) FactoryX, Netherlands/Australia/Germany. All rights reserved.
//
// Project: Media Foundation - MFPack - Samples
// Project location: https://sourceforge.net/projects/MFPack
//                   https://github.com/FactoryXCode/MfPack
// Module: frmFxRecordAdmin.pas
// Kind: Pascal Unit
// Release date: 10-08-2026
// Language: ENU
//
// Revision Version: 4.0.0
// Description: Desktop administration of the FxRecord service on a LAN server.
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
unit frmFxRecordAdmin;

interface

uses

  {WinApi}
  WinApi.Windows,
  WinApi.Messages,
  WinApi.WinSvc,
  {System}
  System.SysUtils,
  System.Classes,
  {Vcl}
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  {Application}
  FxRecord.Config,
  FxRecordAdmin.Remote;

type

  TfrmFxRecordAdmin = class(TForm)
    pnlConnection: TPanel;
    lblServer: TLabel;
    edServer: TEdit;
    btnConnect: TButton;
    lblWindowsIdentity: TLabel;
    lblSharedConfig: TLabel;
    edSharedConfig: TEdit;
    lblServerConfig: TLabel;
    edServerConfig: TEdit;
    btnStart: TButton;
    btnStop: TButton;
    btnRestart: TButton;
    btnRefresh: TButton;
    lblService: TLabel;
    PageControl: TPageControl;
    tabRecorder: TTabSheet;
    Panel1: TPanel;
    Bevel1: TBevel;
    lblStreamPath: TLabel;
    lblArchivePath: TLabel;
    lblProfile: TLabel;
    lblFragmentduration: TLabel;
    lblRetentionDays: TLabel;
    lblWarningGB: TLabel;
    lblCriticalGB: TLabel;
    lblPollingInterval: TLabel;
    lblMp3Rate: TLabel;
    lblMp3BitRate: TLabel;
    lblAacRate: TLabel;
    lblAacBitRate: TLabel;
    lblAacLimits: TLabel;
    Label1: TLabel;
    edStreamPath: TEdit;
    edArchivePath: TEdit;
    cbOutputProfile: TComboBox;
    edFragmentduration: TEdit;
    edRetentionDays: TEdit;
    edWarningGB: TEdit;
    edCriticalGB: TEdit;
    chkRequireLive: TCheckBox;
    edPollingInterval: TEdit;
    cbMp3Rate: TComboBox;
    cbMp3BitRate: TComboBox;
    cbAacRate: TComboBox;
    cbAacBitRate: TComboBox;
    lblLiveTimeout: TLabel;
    edLiveTimeout: TEdit;
    lblPathHelp: TLabel;
    tabServiceLog: TTabSheet;
    memServiceLog: TMemo;
    tabAlertStatus: TTabSheet;
    memAlertStatus: TMemo;
    tabActivity: TTabSheet;
    memActivity: TMemo;
    pnlActions: TPanel;
    lblChanges: TLabel;
    btnSave: TButton;
    btnApply: TButton;
    btnClose: TButton;
    lblOperation: TLabel;
    RefreshTimer: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ConnectionChanged(Sender: TObject);
    procedure SettingsChanged(Sender: TObject);
    procedure cbOutputProfileChange(Sender: TObject);
    procedure ConnectClick(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure RestartClick(Sender: TObject);
    procedure RefreshClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);

  private
    FBusy: Boolean;
    FConnected: Boolean;
    FLoading: Boolean;
    FDirty: Boolean;
    FRefreshing: Boolean;
    FHasPendingAction: Boolean;
    FCloseRequested: Boolean;
    FPendingAction: TFxAdminAction;
    FState: DWORD;
    FOriginalText: string;
    FSettings: TFxRecordSettings;
    FConnection: TFxAdminConnection;

    procedure AddLog(const AText: string);
    procedure UpdateControls();
    procedure LoadControls();
    procedure ReadControls();
    procedure RunAction(AAction: TFxAdminAction);
    procedure AdminResult(var AMessage: TMessage); message FX_RECORD_ADMIN_RESULT;

  protected

    procedure StartWorker(AAction: TFxAdminAction;
                          const ANewText: string); virtual;
  end;

var
  FxRecordAdminForm: TfrmFxRecordAdmin;


implementation

{$R *.dfm}

uses

  {System}
  System.Win.Registry,
  {Vcl}
  Vcl.Dialogs;

const
  PROFILE_KEY = 'Software\FactoryX\FxRecordAdmin';


procedure TfrmFxRecordAdmin.FormCreate(Sender: TObject);
var
  Registry: TRegistry;

begin

  FLoading := True;

  try
    SetDefaultFxRecordSettings(FSettings,
                               'C:\FxRecord');
    Registry := TRegistry.Create(KEY_READ);

    try
      Registry.RootKey := HKEY_CURRENT_USER;

      if Registry.OpenKey(PROFILE_KEY,
                          False) then
        begin
          if Registry.ValueExists('Server') then
            edServer.Text := Registry.ReadString('Server');
          if Registry.ValueExists('SharedConfig') then
            edSharedConfig.Text := Registry.ReadString('SharedConfig');
        end;

    finally
      Registry.Free;
    end;

    LoadControls();

  finally
    FLoading := False;
  end;

  UpdateControls();
  AddLog('Ready. Enter the LAN server and its shared FxRecord ini-filename.');
end;


procedure TfrmFxRecordAdmin.FormCloseQuery(Sender: TObject;
                                           var CanClose: Boolean);
begin

  CanClose := not FBusy and not FHasPendingAction;

  if CanClose then
    RefreshTimer.Enabled := False
  else
    if FRefreshing and not FHasPendingAction then
      begin
        // Close the visible UI immediately. Keep its message target alive until
        // the read-only worker returns, then finish closing without another poll.
        FCloseRequested := True;
        RefreshTimer.Enabled := False;
        Hide;
      end
    else
      lblOperation.Caption := 'Wait for the current server command to finish before closing.';
end;


procedure TfrmFxRecordAdmin.AddLog(const AText: string);
begin

  memActivity.Lines.Add(FormatDateTime('hh:nn:ss',
                                       Now) + '  ' + AText);
  while (memActivity.Lines.Count > 1000) do
    memActivity.Lines.Delete(0);
  memActivity.SelStart := Length(memActivity.Text);
end;


procedure TfrmFxRecordAdmin.ConnectionChanged(Sender: TObject);
begin

  if FLoading or (csLoading in ComponentState) or (csReading in ComponentState) then
    Exit;

  FConnected := False;
  FState := 0;
  RefreshTimer.Enabled := False;
  edServerConfig.Clear();
  lblService.Caption := 'FxRecord service: not connected';
  UpdateControls();
end;


procedure TfrmFxRecordAdmin.SettingsChanged(Sender: TObject);
begin

  if FLoading or (csLoading in ComponentState) or (csReading in ComponentState) then
    Exit;

  FDirty := True;
  UpdateControls();
end;


procedure TfrmFxRecordAdmin.cbOutputProfileChange(Sender: TObject);
begin

  SettingsChanged(Sender);
end;


procedure TfrmFxRecordAdmin.UpdateControls();
var
  Ready: Boolean;
  Mp3: Boolean;
  Aac: Boolean;

begin

  Ready := FConnected and (not FBusy or FRefreshing) and not FHasPendingAction and not FCloseRequested;

  edServer.Enabled := not FBusy;
  edSharedConfig.Enabled := not FBusy;
  btnConnect.Enabled := not FBusy;
  btnStart.Enabled := Ready and (FState = SERVICE_STOPPED);
  btnStop.Enabled := Ready and (FState = SERVICE_RUNNING);
  btnRestart.Enabled := Ready and (FState = SERVICE_RUNNING);
  btnRefresh.Enabled := Ready;
  btnSave.Enabled := Ready and (FState = SERVICE_STOPPED);
  btnApply.Enabled := Ready and (FState in [SERVICE_RUNNING,
                                            SERVICE_STOPPED]);
  btnClose.Enabled := (not FBusy or FRefreshing) and not FHasPendingAction and not FCloseRequested;
  Panel1.Enabled := Ready;

  Mp3 := Ready and SameText(cbOutputProfile.Text,
                            'AVI-H264-MP3');

  Aac := Ready and SameText(cbOutputProfile.Text,
                            'MP4-H264-AAC');

  cbMp3Rate.Enabled := Mp3;
  cbMp3BitRate.Enabled := Mp3;
  lblMp3Rate.Enabled := Mp3;
  lblMp3BitRate.Enabled := Mp3;
  cbAacRate.Enabled := Aac;
  cbAacBitRate.Enabled := Aac;
  lblAacRate.Enabled := Aac;
  lblAacBitRate.Enabled := Aac;
  lblAacLimits.Enabled := Aac;

  if FDirty then
    lblChanges.Caption := 'Unsaved recorder settings'
  else
    if FConnected then
      lblChanges.Caption := 'Recorder settings loaded from the server'
    else
      lblChanges.Caption := 'Connect to load the recorder settings.';
end;


procedure TfrmFxRecordAdmin.LoadControls();
begin

  FLoading := True;

  try
    edStreamPath.Text := FSettings.StreamPath;
    edArchivePath.Text := FSettings.ArchivePath;
    cbOutputProfile.ItemIndex := cbOutputProfile.Items.IndexOf(FSettings.OutputProfile);
    edFragmentduration.Text := IntToStr(FSettings.FragmentDuration);
    edRetentionDays.Text := IntToStr(FSettings.RetentionDays);
    edWarningGB.Text := IntToStr(FSettings.WarningFreeGB);
    edCriticalGB.Text := IntToStr(FSettings.CriticalFreeGB);
    edPollingInterval.Text := IntToStr(FSettings.PollIntervalMs);
    edLiveTimeout.Text := IntToStr(FSettings.LiveStaleSeconds);
    chkRequireLive.Checked := FSettings.RequireLiveStream;

    case FSettings.Mp3SampleRate of
      44100: cbMp3Rate.ItemIndex := 0;
      48000: cbMp3Rate.ItemIndex := 1;
      32000: cbMp3Rate.ItemIndex := 2;
    else
      cbMp3Rate.ItemIndex := -1;
    end;

    cbMp3BitRate.ItemIndex := cbMp3BitRate.Items.IndexOf(IntToStr(FSettings.Mp3BitRateKbps));

    case FSettings.AacSampleRate of
      44100: cbAacRate.ItemIndex := 0;
      48000: cbAacRate.ItemIndex := 1;
    else
      cbAacRate.ItemIndex := -1;
    end;

    cbAacBitRate.ItemIndex := cbAacBitRate.Items.IndexOf(IntToStr(FSettings.AacBitRateKbps));

  finally
    FLoading := False;
  end;
end;


procedure TfrmFxRecordAdmin.ReadControls();
begin

  FSettings.StreamPath := Trim(edStreamPath.Text);
  FSettings.ArchivePath := Trim(edArchivePath.Text);
  FSettings.OutputProfile := cbOutputProfile.Text;

  FSettings.FragmentDuration := StrToIntDef(edFragmentduration.Text,
                                            0);
  FSettings.RetentionDays := StrToIntDef(edRetentionDays.Text,
                                         0);

  FSettings.WarningFreeGB := StrToIntDef(edWarningGB.Text,
                                         0);

  FSettings.CriticalFreeGB := StrToIntDef(edCriticalGB.Text,
                                          0);

  FSettings.PollIntervalMs := StrToIntDef(edPollingInterval.Text,
                                          0);

  FSettings.LiveStaleSeconds := StrToIntDef(edLiveTimeout.Text,
                                            0);

  FSettings.RequireLiveStream := chkRequireLive.Checked;

  case cbMp3Rate.ItemIndex of
    0: FSettings.Mp3SampleRate := 44100;
    1: FSettings.Mp3SampleRate := 48000;
    2: FSettings.Mp3SampleRate := 32000;
  else
    FSettings.Mp3SampleRate := 0;
  end;

  case cbAacRate.ItemIndex of
    0: FSettings.AacSampleRate := 44100;
    1: FSettings.AacSampleRate := 48000;
  else
    FSettings.AacSampleRate := 0;
  end;

  FSettings.Mp3BitRateKbps := StrToIntDef(cbMp3BitRate.Text,
                                          0);

  FSettings.AacBitRateKbps := StrToIntDef(cbAacBitRate.Text,
                                          0);
  ValidateSettings(FSettings);
end;


procedure TfrmFxRecordAdmin.RunAction(AAction: TFxAdminAction);
var
  NewText: string;
  Registry: TRegistry;

begin

  if FCloseRequested then
    Exit;

  if FBusy then
    begin
      // A refresh only reads server state. Keep commands available, and run the
      // selected command after that read finishes rather than overlapping workers.
      if FRefreshing and not FHasPendingAction and (AAction <> aaRefresh) then
        begin
          FPendingAction := AAction;
          FHasPendingAction := True;
          lblOperation.Caption := 'Command queued; waiting for the current status refresh...';
          UpdateControls();
        end;

      Exit;
  end;

  try
    if (AAction <> aaConnect) and not FConnected then
      raise Exception.Create('Connect to the server first.');

    if (AAction = aaConnect) then
      begin
        FConnection.Machine := Trim(edServer.Text);
        if Trim(edSharedConfig.Text) = '' then
          edSharedConfig.Text := #92#92 + FConnection.Machine + #92 + 'FxRecord' + #92 + 'FxRecord.ini';

        FConnection.ConfigFile := Trim(edSharedConfig.Text);
        ValidateConnection(FConnection);
        Registry := TRegistry.Create;

        try
          Registry.RootKey := HKEY_CURRENT_USER;
          if Registry.OpenKey(PROFILE_KEY,
                              True) then
            begin
              Registry.WriteString('Server',
                                   FConnection.Machine);

              Registry.WriteString('SharedConfig',
                                   FConnection.ConfigFile);
            end;

        finally
          Registry.Free;
        end;
    end;

    NewText := '';

    if AAction in [aaSave, aaApply] then
      begin
        ReadControls();
        NewText := SettingsToText(FOriginalText,
                                  FSettings);
      end;

    FBusy := True;
    FRefreshing := (AAction = aaRefresh);
    RefreshTimer.Enabled := False;
    UpdateControls();

    case AAction of
      aaConnect: lblOperation.Caption := 'Connecting to the LAN server...';
      aaRefresh: lblOperation.Caption := 'Refreshing service status and logs...';
      aaStart: lblOperation.Caption := 'Starting FxRecord...';
      aaStop: lblOperation.Caption := 'Stopping FxRecord and completing recordings...';
      aaRestart: lblOperation.Caption := 'Restarting FxRecord...';
      aaSave: lblOperation.Caption := 'Backing up and saving recorder settings...';
      aaApply: lblOperation.Caption := 'Saving settings and restarting FxRecord if it was running...';
    end;

    if (AAction <> aaRefresh) then
      AddLog(lblOperation.Caption);

    StartWorker(AAction,
                NewText);

  except
    on E: Exception do
      begin
        FBusy := False;
        FRefreshing := False;
        RefreshTimer.Enabled := FConnected;
        UpdateControls();
        AddLog(E.Message);
        ShowMessage(E.Message);
      end;
  end;
end;


procedure TfrmFxRecordAdmin.StartWorker(AAction: TFxAdminAction;
                                        const ANewText: string);
begin

  TFxAdminWorker.Create(Handle,
                        FConnection,
                        AAction,
                        FOriginalText,
                        ANewText).Start();
end;


procedure TfrmFxRecordAdmin.AdminResult(var AMessage: TMessage);
var
  Item: TFxAdminResult;
  PendingAction: TFxAdminAction;

begin

  Item := TFxAdminResult(AMessage.LParam);

  try
    FBusy := False;
    FRefreshing := False;

    if FCloseRequested then
      begin
        RefreshTimer.Enabled := False;
        Close();
        Exit;
      end;

    FState := Item.State;

    if (Item.ServerConfigFile <> '') then
      begin
        FConnection.ServerConfigFile := Item.ServerConfigFile;
        edServerConfig.Text := Item.ServerConfigFile;
      end;

    if ((Item.Action = aaConnect) and (Item.ErrorText = '')) or Item.ConfigSaved then
      begin
        FOriginalText := Item.ConfigText;
        SettingsFromText(FOriginalText, FConnection.ServerConfigFile, FSettings);
        LoadControls();
        FDirty := False;
      end;

    if (Item.Action = aaConnect) then
      FConnected := (Item.ErrorText = '');

    if (Item.LogText <> '') then
      memServiceLog.Text := Item.LogText;

    if (Item.StatusText <> '') then
      memAlertStatus.Text := Item.StatusText;

    lblService.Caption := Format('FxRecord: %s  |  PID %d  |  Exit %d/%d',
                                 [ServiceStateText(Item.State), Item.ProcessId, Item.ExitCode, Item.SpecificExitCode]);

    if (Item.Notice <> '') then
      AddLog(Item.Notice);

    if (Item.ErrorText <> '') then
      begin
        lblOperation.Caption := 'Operation failed. See Admin activity.';
        AddLog(Item.ErrorText);

        if Item.ConfigSaved then
          AddLog('Settings were saved, but the following service operation failed.');

        if (Item.Action <> aaRefresh) then
          ShowMessage(Item.ErrorText);
      end
    else
      begin
        lblOperation.Caption := 'Updated ' + FormatDateTime('hh:nn:ss',
                                                            Now);
        if (Item.Action <> aaRefresh) then
          AddLog('Operation completed.');
      end;

    UpdateControls();
    RefreshTimer.Enabled := FConnected;

  finally
    Item.Free;
  end;

  if FHasPendingAction then
    begin
      PendingAction := FPendingAction;
      FHasPendingAction := False;
      RunAction(PendingAction);
    end;
end;


procedure TfrmFxRecordAdmin.ConnectClick(Sender: TObject);
begin

  RunAction(aaConnect);
end;


procedure TfrmFxRecordAdmin.StartClick(Sender: TObject);
begin

  RunAction(aaStart);
end;


procedure TfrmFxRecordAdmin.StopClick(Sender: TObject);
begin

  RunAction(aaStop);
end;


procedure TfrmFxRecordAdmin.RestartClick(Sender: TObject);
begin

  RunAction(aaRestart);
end;


procedure TfrmFxRecordAdmin.RefreshClick(Sender: TObject);
begin

  RunAction(aaRefresh);
end;


procedure TfrmFxRecordAdmin.SaveClick(Sender: TObject);
begin

  RunAction(aaSave);
end;


procedure TfrmFxRecordAdmin.ApplyClick(Sender: TObject);
begin

  RunAction(aaApply);
end;


procedure TfrmFxRecordAdmin.CloseClick(Sender: TObject);
begin

  Close();
end;

end.
