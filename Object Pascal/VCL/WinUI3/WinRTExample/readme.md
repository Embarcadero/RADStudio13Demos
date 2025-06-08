# VCL.WinRTExample Sample

## Introduction

WinUI 3 is Microsoft's new native UI framework available for packaged
and non-packaged GUI applications (in Windows terms, that is, nothing to
do with Delphi packages). WinUI 3 is part of the Windows App SDK
(previously known as Project Reunion), where the Windows App SDK is
separate to the Windows SDK (despite the very similar names). WinUI 3 is
the current UI framework in the WinRT (Windows Runtime) architecture.

The sample project SampleWinRT is intended to show how to construct a
simple Delphi GUI application purely out of Microsoft's WinUI 3 (1.0)
framework. Pre-release versions of WinUI3 required the application to be
deployed as a Windows packaged application, but WinUI 3 (1.0) removes
that restriction meaning that you can build a WinUI 3 app in Delphi as a
regular app.

You can find more about WinUI 3 here:
<https://docs.microsoft.com/en-us/windows/apps/winui/winui3>.

You can find more about the Windows App SDK here:
<https://docs.microsoft.com/en-us/windows/apps/windows-app-sdk>.

## Prerequisites

In order to build and deploy an unpackaged app you need a couple of
things, as detailed on
<https://docs.microsoft.com/en-us/windows/apps/windows-app-sdk/deploy-unpackaged-apps>.

Firstly you need the Windows App SDK installer, which you can get from a
download link on the aforementioned Microsoft page, or pull it down from
<https://aka.ms/windowsappsdk/1.0-stable/msix-installer>. This gives you
the redistributable file archive, currently called
Microsoft.WindowsAppRuntime.Redist.1.0.0.zip, which contains installers
for x86 and x64 platforms (both called WindowsAppRuntimeInstaller.exe)
in sensibly named folders.

Running the installer (with elevated privileges) will ensure that you
have the Windows App Runtime installed – it goes into hidden folders
under C:\\Program Files\\WindowsApps, for example the x86 version might be
installed within
C:\\Program Files\\WindowsApps\\Microsoft.WindowsAppRuntime.1.0\_0.319.455.0\_x86\_\_8wekyb3d8bbwe.

The second thing you need is the Windows App Runtime loader DLL,
Microsoft.WindowsAppRuntime.Bootstrap.dll. This file is obtained from
within the Windows App SDK NuGet package, currently
Microsoft.WindowsAppSDK.1.0.0.nupkg, which is available from
<https://www.nuget.org/packages/Microsoft.WindowsAppSDK> in the folder
runtimes\\win10-x86\\native or runtimes\\win10-x64\\native. This DLL should
be placed alongside your executable in order to be located at
application startup when the relevant APIs are called. The loader DLL
(or bootstrap DLL) is responsible for locating a suitable version of the
Windows App Runtime, which implements WinUI 3, based on the version
values passed into its startup API.

## Introduction to the sample

The sample application is built as a console app, not out of necessity,
but so information can be written to the console window as the
application progresses.

Note: WinUI 3 requires you to run the process *without* elevated
privileges. As such, the sample checks this and exits with a simple
message if it finds elevated privileges. Without this check in place,
WinUI 3 crashes the application in a seemingly graceless manner.

Assuming we pass the privileges check the app calls the initialization
API in the loader DLL, `MddBootstrapInitialize`, and if that locates and
starts up the Windows App Runtime the application then proceeds with
further initialization. Before exiting the app calls
`MddBootstrapShutdown` to clean up.

```
uses 
  WinRT; 
const 
  // From include\WindowsAppSDK-VersionInfo.h in WinAppSDK NuGet package 
  WINDOWSAPPSDK_RELEASE_MAJORMINOR = $00010000; 
  WINDOWSAPPSDK_RUNTIME_VERSION_UINT64 = $0000013F01C70000; 
  WINDOWSAPPSDK_RUNTIME_VERSION_DOTQUADSTRING = '0.319.455.0'; 
var 
  PackageVersion: PACKAGE_VERSION; 
... 
  PackageVersion.Version := WINDOWSAPPSDK_RUNTIME_VERSION_UINT64; 
  var HR := MddBootstrapInitialize(WINDOWSAPPSDK_RELEASE_MAJORMINOR, nil, PackageVersion); 
  if Succeeded(HR) then 
    try 
      Main; 
      WriteLn('Press Enter (again) to continue'); 
      Readln; 
    finally 
      MddBootstrapShutdown; 
    end; 
```

As you can see, the SDK release and runtime package versions are
borrowed from a header (.h) file located within the Windows App SDK
NuGet package.

Within `Main` we call the static `Start` method of the WinUI 3
`Application` object – see
<https://docs.microsoft.com/en-us/windows/winui/api/microsoft.ui.xaml.application.start>.
This takes a callback that will be run when the application initializes,
allowing us to set things up as we wish. Fortuitously, WinRT callbacks
(including WinUI 3 callbacks) have the same implementation as a Delphi
anonymous method so we use an anonymous method to set up our
application's `OnLaunched` event handler.

In WinUI 3 `OnLaunched` is not actually an event handler. Instead
`OnLaunched` -
<https://docs.microsoft.com/en-us/windows/winui/api/microsoft.ui.xaml.application.onlaunched> - is a method that we are expected to override in a class that inherits
from the WinUI `Application` class. How do we cope with this requirement
to inherit from a WinRT class from Delphi?

WinUI helps us out by supplying a mechanism that we can make use of. In
a case like this, inheriting from a WinUI 3 class involves 3 objects:

1) An inner object that gives the base implementation, which is
provided by WinUI, in this case a base `Application` implementation. This inner object will implement an interface that defines the method(s)
we will be providing implementations for; `IApplicationOverrides` in
this case.

2) An outer object (sometimes referred to as a base object) that
provides the custom implementation of the method(s) in question. This
outer object, which we will provide, will also implement
`IApplicationOverrides`. 

3) A wrapper object, which combines the inner and outer object, and is
provided by WinUI.

Here is the code from `Main`:

```
var AppInner: IInspectable; 
var AppOuter: IApplicationOverrides; 
var AppWrapper: IApplication; 

// In this code block we use an anonymous procedure (which Delphi implements as an 
// interface with an Invoke method) that matches the layout of the callback interface 
type 
  TCallbackProc = reference to procedure (p: IApplicationInitializationCallbackParams) safecall;

procedure Main; 
begin 
  // Here we define an anonymous method and cast it to the matching WinUI interface type 
  var CallbackProc: TCallbackProc := 
    procedure (p: IApplicationInitializationCallbackParams) safecall 
    begin 
      // First we create our derived class 
      AppOuter := TDerivedApp.Create as IApplicationOverrides; 
      // Then we get the IApplicationFactory... 
      var Factory := TApplication.Factory; 
      // ... and use it to get an IApplication wrapper, AppWrapper, 
      // and an IApplicationOverrides inner as well 
      AppWrapper := Factory.CreateInstance(AppOuter, AppInner); 
      // We store the inner object in the outer one so 
      // we can call the base functionality when needed 
      AppOuter.Inner := AppInner as IApplicationOverrides; 
  end; 
  var AppInitCallback := ApplicationInitializationCallback(CallbackProc); 
  TApplication.Start(AppInitCallback); 
end; 
```

The application customization code is from this class:

```
type 
  TDerivedApp = class(TInspectableObject, IApplicationOverrides) 
  private 
    FInner: IApplicationOverrides; 
  public 
    { IApplicationOverrides methods } 
    procedure OnLaunched(args: ILaunchActivatedEventArgs); safecall; 
  ... 
    property Inner: IApplicationOverrides read FInner write FInner; 
end;
```

The `OnLaunched` method is then at liberty to do all the app setup
required. In this case we create and set up a `Window` - <https://docs.microsoft.com/en-us/windows/winui/api/microsoft.ui.xaml.window> and populate it with some controls.

Look in the code for all the details of what goes on, but in summary:

We create a `StackPanel` control and put it in the window, then a button
is created with a `Click` event handler and added to the `StackPanel`.

Next we use some XAML to create another `StackPanel` and a button child
control, again with a `Click` event handler, adding the `StackPanel` to
the window. That gives us 2 approaches to achieve the same goal.

Finally some more XAML is used to create a `Grid` and within that a
`TextBlock`, which then has a couple of event handlers added for
`OnPointerEntered` and `OnPointerExited`.

Ultimately we end up with a window showing a couple of buttons and a
text block. The buttons can be clicked to change their caption and the
text block changes color when you move the mouse into and out of it:

![WinUIDesktop.png](Readme%20Files/WinUIDesktop.png)

Note: Unlike C# and C++, the language projection for Delphi does not
currently incorporate all the various interfaces implemented by WinRT
and WinUI 3 objects into unified proxy classes, and so there is a lot
more interface work going on than would be the case elsewhere.
