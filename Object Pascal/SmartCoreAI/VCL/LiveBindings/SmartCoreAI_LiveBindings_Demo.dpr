//---------------------------------------------------------------------------

// This software is Copyright (c) 2025 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

program SmartCoreAI_LiveBindings_Demo;

uses
  Vcl.Forms,
  LBMain in 'LBMain.pas' {Frm_LBMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrm_LBMain, Frm_LBMain);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
