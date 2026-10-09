// FactoryX
//
// Copyright (c) FactoryX, Netherlands/Australia/Germany. All rights reserved.
//
// Project: Media Foundation - MFPack - Samples
// Project location: https://sourceforge.net/projects/MFPack
//                   https://github.com/FactoryXCode/MfPack
// Module: FxRecord.Log.pas
// Kind: Pascal Unit
// Release date: 10-08-2026
// Language: ENU
//
// Revision Version: 4.0.0
// Description: Writes recorder and service diagnostics to the configuration log.
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
unit FxRecord.Log;

interface

function AppendFxRecordLog(const AConfigFileName, ALevel, AText: string): Boolean;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils;

var
  LogLock: TRTLCriticalSection;

function AppendFxRecordLog(const AConfigFileName, ALevel, AText: string): Boolean;
var
  LogFileName, Line: string;
begin
  Result := False;
  LogFileName := ChangeFileExt(AConfigFileName, '.log');
  Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' [' +
          UpperCase(ALevel) + '] ' + AText + sLineBreak;
  EnterCriticalSection(LogLock);
  try
    try
      TFile.AppendAllText(LogFileName, Line, TEncoding.UTF8);
      Result := True;
    except
      on E: Exception do
        OutputDebugString(PChar('FxRecord cannot write ' + LogFileName + ': ' + E.Message));
    end;
  finally
    LeaveCriticalSection(LogLock);
  end;
end;

initialization
  InitializeCriticalSection(LogLock);
finalization
  DeleteCriticalSection(LogLock);
end.