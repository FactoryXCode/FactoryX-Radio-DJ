unit FxRecord.Converter;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils;

type
  TFxConversionThread = class(TThread)
  private
    FInputFileName: string;
    FPartialFileName: string;
    FFinalFileName: string;
    FFmpegFileName: string;
    FErrorText: string;
    FSucceeded: Boolean;
  protected
    procedure Execute(); override;
  public
    constructor Create(const AFFmpegFileName,
                             AInputFileName,
                             APartialFileName,
                             AFinalFileName: string);
    property ErrorText: string read FErrorText;
    property FinalFileName: string read FFinalFileName;
    property InputFileName: string read FInputFileName;
    property Succeeded: Boolean read FSucceeded;
  end;

function FindFxRecordFFmpeg(): string;

implementation

uses
  System.IOUtils;

function FindFxRecordFFmpeg(): string;
var
  AppFolder: string;
  DevelopmentFile: string;
begin
  AppFolder := ExtractFileDir(ParamStr(0));
  Result := TPath.Combine(AppFolder, 'ffmpeg.exe');
  if FileExists(Result) then
    Exit;

  { Development fallback. A deployed FxRecord installation should place
    ffmpeg.exe beside FxRecord.exe. }
  DevelopmentFile := TPath.GetFullPath(TPath.Combine(AppFolder,
    '..\..\..\..\Samples\MfCastPlayer II\Binaries\ffmpeg.exe'));
  if FileExists(DevelopmentFile) then
    Result := DevelopmentFile
  else
    Result := '';
end;

function QuoteArgument(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '\"', [rfReplaceAll]) + '"';
end;

constructor TFxConversionThread.Create(const AFFmpegFileName,
  AInputFileName, APartialFileName, AFinalFileName: string);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FFmpegFileName := AFFmpegFileName;
  FInputFileName := AInputFileName;
  FPartialFileName := APartialFileName;
  FFinalFileName := AFinalFileName;
end;

procedure TFxConversionThread.Execute();
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  CommandLine: string;
  ExitCode: DWORD;
begin
  FSucceeded := False;
  FErrorText := '';
  if FFmpegFileName = '' then
    begin
      FErrorText := 'ffmpeg.exe was not found beside FxRecord.exe.';
      Exit;
    end;

  DeleteFile(PChar(FPartialFileName));
  CommandLine := QuoteArgument(FFmpegFileName) +
    ' -nostdin -hide_banner -loglevel error -y -i ' +
    QuoteArgument(FInputFileName) +
    ' -map 0:v:0 -map 0:a:0 -vf fps=25' +
    ' -c:v libx264 -preset veryfast -profile:v baseline' +
    ' -pix_fmt yuv420p -b:v 1200k -maxrate 5600k -bufsize 2400k' +
    ' -vtag H264 -c:a libmp3lame -b:a 192k -ar 44100 -ac 2' +
    ' -f avi ' + QuoteArgument(FPartialFileName);

  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;
  ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));
  UniqueString(CommandLine);
  if not CreateProcess(nil, PChar(CommandLine), nil, nil, False,
                       CREATE_NO_WINDOW, nil, nil, StartupInfo,
                       ProcessInfo) then
    begin
      FErrorText := 'Cannot start ffmpeg.exe. ' +
                    SysErrorMessage(GetLastError());
      Exit;
    end;
  try
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
    ExitCode := DWORD(-1);
    GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);
  finally
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ProcessInfo.hProcess);
  end;

  if ExitCode <> 0 then
    begin
      FErrorText := Format('ffmpeg.exe returned exit code %d.', [ExitCode]);
      Exit;
    end;
  if not FileExists(FPartialFileName) then
    begin
      FErrorText := 'The AVI converter did not create an output file.';
      Exit;
    end;
  if not MoveFileEx(PChar(FPartialFileName), PChar(FFinalFileName),
                    MOVEFILE_WRITE_THROUGH) then
    begin
      FErrorText := 'Cannot finalize AVI recording. ' +
                    SysErrorMessage(GetLastError());
      Exit;
    end;
  DeleteFile(PChar(FInputFileName));
  FSucceeded := True;
end;

end.
