//---------------------------------------------------------------------------

// This software is Copyright (c) 2025 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

program JSON_OpenAI_VCL;

uses
  Vcl.Forms,
  JSONMain in 'JSONMain.pas' {Frm_JsonMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrm_JsonMain, Frm_JsonMain);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
