{*******************************************************}
{                                                       }
{              WinRT Hello World XAML App               }
{                                                       }
{ Copyright(c) 1995-2020 Embarcadero Technologies, Inc. }
{                                                       }
{*******************************************************}

program SampleWinRT;

{$APPTYPE CONSOLE}

{$R *.dres}

uses
  System.Win.ComObj,
  System.SysUtils,
  Winapi.Windows,
  Winapi.WinRT,
  Winapi.Microsoft.Ui.Xaml,
  AppInit in 'AppInit.pas';

// To inherit from a WinRT class involves 3 objects:
//   i) inner object, providing the base implementation, provided by the WinRT type we are extending
//  ii) outer object (aka base object), defining the virtual method overrides, provided by us
// iii) wrapper object to combine inner/outer objects, provided by the WinRT type we are extending
// In the example below the Application virtual methods we can extend are
// defined in IApplicationOverrides and implemented in TDerivedApp, which represents the outer object.
// IApplicationFactory.CreateInstance takes our outer object and returns the inner, which we store in
// a field in the outer (so we can call base behaviour) and also returns us the wrapper object that we store in App.

// These 3 have to be outside of the callback so they don't get released by its epilogue code
// To be sure, we'll have them as global variables here
var AppInner: IInspectable;
var AppOuter: IApplicationOverrides;
var AppWrapper: IApplication;

// In this code block we use an anonymous procedure (which Delphi implements as an
// interface with an Invoke method) that matches the binary layout of the callback interface
type
  TCallbackProc = reference to procedure (p: IApplicationInitializationCallbackParams) safecall;

procedure Main;
begin
  // Here we define an anonymous procedure and cast it to the matching WinUI interface type
  var CallbackProc: TCallbackProc :=
    procedure (p: IApplicationInitializationCallbackParams) safecall
    begin
      WriteLn('IApplicationInitializationCallback starting');
      // First we create our derived class
      var Outer := TDerivedApp.Create;
      AppOuter := Outer as IApplicationOverrides;
      // Then we get the IApplicationFactory...
      var Factory := TApplication.Factory;
      // ... and use it to get an IApplication wrapper, AppWrapper,
      // and an IApplicationOverrides inner as well
      AppWrapper := Factory.CreateInstance(AppOuter, AppInner);
      // We store the inner object in the outer one so we 
      // can call the base functionality when needed
      Outer.Inner := AppInner as IApplicationOverrides;
      WriteLn('IApplicationInitializationCallback ending');
    end;
  var AppInitCallback := ApplicationInitializationCallback(CallbackProc);
  TApplication.Start(AppInitCallback);
  AppWrapper := nil; // App needs to be _Released before AppInner, otherwise WinUI gets upset
end;

function IsElevated: Boolean;
const
  TokenElevation = TTokenInformationClass(20);
var
  LTokenHandle: THandle;
  LLen: Cardinal;
  LTokenElevation: TOKEN_ELEVATION;
  LGotToken: Boolean;
begin
  Result := False;
  if CheckWin32Version(6, 0) then
  begin
    LTokenHandle := 0;
    LGotToken := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, LTokenHandle);
    if not LGotToken and (GetLastError = ERROR_NO_TOKEN) then
      LGotToken := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, LTokenHandle);
    if LGotToken then
      try
        LLen := 0;
        if GetTokenInformation(LTokenHandle, TokenElevation, @LTokenElevation, SizeOf(LTokenElevation), LLen) then
          Result := LTokenElevation.TokenIsElevated <> 0
      finally
        CloseHandle(LTokenHandle);
      end
  end
  else
    Result := True
end;

const
  // From include\WindowsAppSDK-VersionInfo.h in the Microsoft.WindowsAppSDK.1.0.0 NuGet package
  WINDOWSAPPSDK_RELEASE_MAJORMINOR = $00010000;
  WINDOWSAPPSDK_RUNTIME_VERSION_UINT64 = $0000013F01C70000;
  WINDOWSAPPSDK_RUNTIME_VERSION_DOTQUADSTRING = '0.319.455.0';
var
  PackageVersion: PACKAGE_VERSION;

begin
  if IsElevated then
  begin
    WriteLn('Please run without elevated privileges.');
    WriteLn('DynamicDependencies doesn''t support elevation. See Issue #567 https://github.com/microsoft/ProjectReunion/issues/567');
  end
  else
  begin
    PackageVersion.Version := WINDOWSAPPSDK_RUNTIME_VERSION_UINT64;
    var HR := MddBootstrapInitialize(WINDOWSAPPSDK_RELEASE_MAJORMINOR, nil, PackageVersion);
    if Succeeded(HR) then
      try
        Main
      finally
        MddBootstrapShutdown;
      end
    else
      WriteLn('Failed to load Microsoft.WindowsAppRuntime.Bootstrap.dll - error: $', IntToHex(HR, 8));
  end;
  WriteLn('Press Enter to exit');
  Readln;
end.
