program JSON_OpenAI_FMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  UJsonMain in 'UJsonMain.pas' {Frm_JsonMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrm_JsonMain, Frm_JsonMain);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
