!include "MUI.nsh"
!include "$%DEVROOT%\other\nsis\dotnet_check.nsi"
!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Russian"

InstallDir "$PROGRAMFILES\S-BANK\SB.Sync.Svc"
OutFile "install_SB.Sync.Svc-${__DATE__}.exe"
Name "S-BANK: Служба синхронизации"

Function .OnInit
   Call IsDotNETInstalled
   Pop $0
   StrCmp $0 1 found.NETFramework no.NETFramework
   found.NETFramework:
    Goto done
   no.NETFramework:
    MessageBox MB_OK|MB_ICONSTOP "Не установлен .NET Framework!"
    Abort
   done:
FunctionEnd

Section "Приложение"
  SetOutPath $INSTDIR

  IfFileExists "$INSTDIR\SB.Sync.Svc.exe" 0 not_exists1
  ExecWait "$INSTDIR\SB.Sync.Svc.exe -stopsvc"
  not_exists1:
  File ..\..\SB.Sync.Svc\bin\Release\SB.Sync.Svc.exe
SectionEnd

Section "Библиотеки"
  SetOutPath $INSTDIR
  File ..\..\SB.Sync.Svc\bin\Release\FirebirdSql.Data.FirebirdClient.dll
  File ..\..\SB.Sync.Svc\bin\Release\ICSharpCode.SharpZipLib.dll
  File ..\..\SB.Sync.Svc\bin\Release\SB.Svc.Base.dll
;  File ..\..\SB.Sync.Svc\bin\Release\SB.Lib.dll
  File ..\..\SB.Sync.Svc\bin\Release\SB.Sync.Svc.exe.config
  File ..\..\SB.Sync.Classes\bin\Release\SB.Sync.Classes.dll
  File /oname=config.sample ..\..\SB.Sync.Svc\bin\Release\config.xml
  File C:\devel\dotnet\Lib\Lib\log4net.dll
SectionEnd

Section "ServiceSetup"
  ExecWait "$INSTDIR\SB.Sync.Svc.exe -setup"
SectionEnd
