program Image_OpenAI_FMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  ImageMain in 'ImageMain.pas' {Frm_ImageMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrm_ImageMain, Frm_ImageMain);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
