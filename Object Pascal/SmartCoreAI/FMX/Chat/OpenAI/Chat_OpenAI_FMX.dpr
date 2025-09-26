program Chat_OpenAI_FMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  UChatMain in 'UChatMain.pas' {Frm_ChatMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrm_ChatMain, Frm_ChatMain);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
