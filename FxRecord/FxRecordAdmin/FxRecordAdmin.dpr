// FactoryX
//
// Copyright (c) FactoryX, Netherlands/Australia/Germany. All rights reserved.
//
// Project: Media Foundation - MFPack - Samples
// Project location: https://sourceforge.net/projects/MFPack
//                   https://github.com/FactoryXCode/MfPack
// Module: FxRecordAdmin.dpr
// Kind: Delphi Application
// Release date: 10-08-2026
// Language: ENU
//
// Revision Version: 4.0.0
// Description: Starts the desktop FxRecord admin application.
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
program FxRecordAdmin;
uses
  Vcl.Forms,
  frmFxRecordAdmin in 'frmFxRecordAdmin.pas' {FxRecordAdminForm},
  FxRecordAdmin.Remote in 'FxRecordAdmin.Remote.pas',
  FxRecord.Config in '..\FxRecord.Config.pas';
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'FactoryX FxRecord Admin';
  Application.CreateForm(TfrmFxRecordAdmin, FxRecordAdminForm);
  Application.Run;
end.
