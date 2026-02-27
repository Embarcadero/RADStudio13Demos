program SmartCoreAI_LiveBindings_FMX_Demo;

uses
  System.StartUpCopy,
  FMX.Forms,
  LBMain in 'LBMain.pas' {Frm_LBMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrm_LBMain, Frm_LBMain);
  Application.Run;
end.
