program FxRecord;

uses
  Vcl.Forms,
  frmFxRecord in 'frmFxRecord.pas' {FxRecordForm},
  FxRecord.Config in 'FxRecord.Config.pas',
  FxRecord.Recorder in 'FxRecord.Recorder.pas',
  FxRecord.Monitor in 'FxRecord.Monitor.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'FactoryX FxRecord';
  Application.CreateForm(TfrmFxRecord, FxRecordForm);
  Application.Run;
end.
