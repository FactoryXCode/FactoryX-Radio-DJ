unit FxRecord.Config;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.IniFiles,
  System.IOUtils;

type
  TFxRecordSettings = record
    Enabled: Boolean;
    StreamPath: string;
    ArchivePath: string;
    PollIntervalMs: Integer;
    RequireLiveStream: Boolean;
    LiveStaleSeconds: Integer;
    WarningFreeGB: Integer;
    CriticalFreeGB: Integer;
    SplitMinutes: Integer;
    RetentionDays: Integer;
    OutputProfile: string;
  end;

procedure SetDefaultFxRecordSettings(out ASettings: TFxRecordSettings;
                                     const ABasePath: string);
procedure LoadFxRecordSettings(const AFileName: string;
                               out ASettings: TFxRecordSettings);
procedure SaveFxRecordSettings(const AFileName: string;
                               const ASettings: TFxRecordSettings);

implementation

function ResolvePath(const ABasePath, AValue: string): string;
begin
  if TPath.IsPathRooted(AValue) then
    Result := TPath.GetFullPath(AValue)
  else
    Result := TPath.GetFullPath(TPath.Combine(ABasePath, AValue));
end;

procedure SetDefaultFxRecordSettings(out ASettings: TFxRecordSettings;
                                     const ABasePath: string);
begin
  ASettings.Enabled := False;
  ASettings.StreamPath := TPath.Combine(ABasePath, 'www\Stream');
  ASettings.ArchivePath := TPath.Combine(ABasePath, 'ComplianceRecordings');
  ASettings.PollIntervalMs := 500;
  ASettings.RequireLiveStream := False;
  ASettings.LiveStaleSeconds := 15;
  ASettings.WarningFreeGB := 20;
  ASettings.CriticalFreeGB := 5;
  ASettings.SplitMinutes := 60;
  ASettings.RetentionDays := 14;
  ASettings.OutputProfile := 'SourceCopy';
end;

procedure LoadFxRecordSettings(const AFileName: string;
                               out ASettings: TFxRecordSettings);
var
  Ini: TMemIniFile;
  BasePath: string;
begin
  BasePath := ExtractFileDir(ExpandFileName(AFileName));
  SetDefaultFxRecordSettings(ASettings, BasePath);
  if not FileExists(AFileName) then
    Exit;

  Ini := TMemIniFile.Create(AFileName, TEncoding.UTF8);
  try
    ASettings.Enabled := Ini.ReadBool('Recorder', 'Enabled', ASettings.Enabled);
    ASettings.StreamPath := ResolvePath(BasePath,
      Ini.ReadString('Recorder', 'StreamPath', ASettings.StreamPath));
    ASettings.ArchivePath := ResolvePath(BasePath,
      Ini.ReadString('Recorder', 'ArchivePath', ASettings.ArchivePath));
    ASettings.PollIntervalMs := EnsureRange(
      Ini.ReadInteger('Recorder', 'PollIntervalMs', ASettings.PollIntervalMs),
      100, 60000);
    ASettings.RequireLiveStream := Ini.ReadBool('Recorder', 'RequireLiveStream',
                                                ASettings.RequireLiveStream);
    ASettings.LiveStaleSeconds := EnsureRange(
      Ini.ReadInteger('Recorder', 'LiveStaleSeconds', ASettings.LiveStaleSeconds),
      5, 3600);
    ASettings.WarningFreeGB := EnsureRange(
      Ini.ReadInteger('Recorder', 'WarningFreeGB', ASettings.WarningFreeGB),
      1, 100000);
    ASettings.CriticalFreeGB := EnsureRange(
      Ini.ReadInteger('Recorder', 'CriticalFreeGB', ASettings.CriticalFreeGB),
      1, ASettings.WarningFreeGB);
    ASettings.SplitMinutes := EnsureRange(
      Ini.ReadInteger('Archive', 'SplitMinutes', ASettings.SplitMinutes), 1, 1440);
    ASettings.RetentionDays := EnsureRange(
      Ini.ReadInteger('Archive', 'RetentionDays', ASettings.RetentionDays), 1, 3650);
    ASettings.OutputProfile := Ini.ReadString('Archive', 'OutputProfile',
                                               ASettings.OutputProfile);
  finally
    Ini.Free();
  end;
end;

procedure SaveFxRecordSettings(const AFileName: string;
                               const ASettings: TFxRecordSettings);
var
  Ini: TMemIniFile;
begin
  ForceDirectories(ExtractFileDir(ExpandFileName(AFileName)));
  Ini := TMemIniFile.Create(AFileName, TEncoding.UTF8);
  try
    Ini.WriteBool('Recorder', 'Enabled', ASettings.Enabled);
    Ini.WriteString('Recorder', 'StreamPath', ASettings.StreamPath);
    Ini.WriteString('Recorder', 'ArchivePath', ASettings.ArchivePath);
    Ini.WriteInteger('Recorder', 'PollIntervalMs', ASettings.PollIntervalMs);
    Ini.WriteBool('Recorder', 'RequireLiveStream', ASettings.RequireLiveStream);
    Ini.WriteInteger('Recorder', 'LiveStaleSeconds', ASettings.LiveStaleSeconds);
    Ini.WriteInteger('Recorder', 'WarningFreeGB', ASettings.WarningFreeGB);
    Ini.WriteInteger('Recorder', 'CriticalFreeGB', ASettings.CriticalFreeGB);
    Ini.WriteInteger('Archive', 'SplitMinutes', ASettings.SplitMinutes);
    Ini.WriteInteger('Archive', 'RetentionDays', ASettings.RetentionDays);
    Ini.WriteString('Archive', 'OutputProfile', ASettings.OutputProfile);
    Ini.UpdateFile();
  finally
    Ini.Free();
  end;
end;

end.
