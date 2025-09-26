program Image_Gemini_FMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  UImageMain in 'UImageMain.pas' {Frm_ImageMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrm_ImageMain, Frm_ImageMain);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
