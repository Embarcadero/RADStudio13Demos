program Mobile_InterBase;

uses
  System.StartUpCopy,
  FMX.Forms,
  FormMain in 'FormMain.pas' {MainFrm},
  InterBase.Connection in 'InterBase.Connection.pas' {MainDM: TDataModule},
  InterBase.Admin in 'InterBase.Admin.pas' {AdminDM: TDataModule},
  InterBase.Constants in 'InterBase.Constants.pas',
  InterBase.Config in 'InterBase.Config.pas',
  DatabaseStructureUpdate in 'DatabaseStructureUpdate.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
