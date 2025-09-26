//---------------------------------------------------------------------------

// This software is Copyright (c) 2025 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

program Image_Gemini_VCL;

uses
  Vcl.Forms,
  ImageMain in 'ImageMain.pas' {FormImage};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormImage, FormImage);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
