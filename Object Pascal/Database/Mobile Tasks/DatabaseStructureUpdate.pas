//---------------------------------------------------------------------------

// This software is Copyright (c) 2021 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit DatabaseStructureUpdate;

interface

uses
  InterBase.Connection, InterBase.Config;

type
  TMyDatabaseStructureUpdate = class
  public
    class function UpdateMetaData(ADM: TMainDM; AConfig: TInterBaseConfigBase): Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TMyDatabaseStructureUpdate }

class function TMyDatabaseStructureUpdate.UpdateMetaData(ADM: TMainDM; AConfig: TInterBaseConfigBase): Boolean;
var
  LCurVersion: Integer;
begin
  Assert(Assigned(ADM), 'Application data module missing');
  Assert(Assigned(AConfig), 'Database configuration details missing');

  Result := False;
  if not ADM.TableExists('VERSION') then
  begin
    // VERSION table stores current version of database metadata.
    // When current version is less than AConfig.Version, then application should upgrade database metadata.
    ADM.Conn.ExecSQL('CREATE TABLE VERSION (VERSION INTEGER NOT NULL)');
    ADM.Conn.ExecSQL('INSERT INTO VERSION (VERSION) VALUES (' + AConfig.Version.ToString + ')');
    LCurVersion := AConfig.Version;
    Result := True;
  end
  else
    LCurVersion := ADM.Conn.ExecSQLScalar('SELECT VERSION FROM VERSION');

  if not ADM.TableExists('TASKS') then
  begin
    // Domains are good practice when it comes to setting up fields. Especially if you have the same field used in multiple locations.
    // You can also set contraints against domains (e.g. Not Null, or contains specific values only)
    // Learn more about domains....    https://www.youtube.com/watch?v=eNES4az929E
    ADM.Conn.ExecSQL('CREATE DOMAIN D_ID INTEGER NOT NULL');
    ADM.Conn.ExecSQL('CREATE DOMAIN D_DESCRIPTION VARCHAR(255)');
    ADM.Conn.ExecSQL('CREATE DOMAIN D_COMPLETED BOOLEAN');

    // With the domains created, we create the database table.
    ADM.Conn.ExecSQL('CREATE TABLE TASKS (ID D_ID PRIMARY KEY, DESCRIPTION D_DESCRIPTION, COMPLETED D_COMPLETED)');
    ADM.Conn.ExecSQL('CREATE GENERATOR GenTASKS_ID');
    ADM.Conn.ExecSQL('SET GENERATOR GenTASKS_ID TO 10');

    // Populate demo data
    ADM.Conn.ExecSQL('INSERT INTO TASKS (ID, DESCRIPTION, COMPLETED) VALUES (1, ''Wake up at 7'', TRUE)');
    ADM.Conn.ExecSQL('INSERT INTO TASKS (ID, DESCRIPTION, COMPLETED) VALUES (2, ''Make coffee'', FALSE)');
    ADM.Conn.ExecSQL('INSERT INTO TASKS (ID, DESCRIPTION, COMPLETED) VALUES (3, ''Walking the dog'', FALSE)');
    Result := True;
  end;

  if LCurVersion < AConfig.Version then
  begin
    // Upgrade database metadata
    // ..........................
    // eg, ALTER TABLE TASKS ADD notes BLOB SUB_TYPE 1
    // ..........................

    // Finally update current version value
    ADM.Conn.ExecSQL('UPDATE VERSION SET VERSION = ' + AConfig.Version.ToString);
  end
  else if LCurVersion > AConfig.Version then
  begin
    // Depending on application the more new database may be incompatible with the application.
    // Or may be compatible ...
    raise Exception.CreateFmt('Database version %d is not compatible with application version %d',
      [LCurVersion, AConfig.Version]);
  end;

  if Result then
    ADM.Conn.RefreshMetadataCache();
end;

end.
