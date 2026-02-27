program Chat_Gemini_VCL;

uses
  Vcl.Forms,
  ChatMain in 'ChatMain.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrm_ChatMain, Frm_ChatMain);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
