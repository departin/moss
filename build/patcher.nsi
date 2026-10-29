; Installs Moss into the official Discord app instead of as its own app.
; Built by scripts/build/patcher.mts. /ROOT=<folder> patches a test Discord folder and leaves the real one alone.
Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "Sections.nsh"
!include "WordFunc.nsh"
!include "StrFunc.nsh"
${StrStr}
${UnStrStr}

!define NAME "Moss for Discord"
!define DIRNAME "MossForDiscord"
!define UNINSTALLER "Uninstall ${NAME}.exe"
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${DIRNAME}"
!define STUB 'require(require("path").join(process.env.LOCALAPPDATA, "Programs", "${DIRNAME}", "moss.asar"));'

Name "${NAME}"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\Programs\${DIRNAME}"
RequestExecutionLevel user
SetCompressor /SOLID lzma
BrandingText "Moss ${VERSION}"
VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${NAME}"
VIAddVersionKey "FileDescription" "${NAME} Setup"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "GPL-3.0-or-later"

Var Root
Var TestMode
Var PRoot
Var Res
Var Newest
Var Cmp
Var Line
Var Find
Var FindName
Var Opened

!define MUI_ICON "${ICON}"
!define MUI_UNICON "${ICON}"
!define MUI_ABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "Add Moss to Discord"
!define MUI_WELCOMEPAGE_TEXT "This puts Moss inside the Discord app you already use, instead of installing it as a separate app.$\r$\n$\r$\nDiscord will close for a moment while Moss is added. To go back to plain Discord, uninstall ${NAME} from Settings, Apps."
!insertmacro MUI_PAGE_WELCOME
!define MUI_COMPONENTSPAGE_TEXT_TOP "Choose which Discord apps get Moss."
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_TITLE "Moss is in Discord"
!define MUI_FINISHPAGE_TEXT "Open Discord and Moss will walk you through a quick setup."
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Open Discord"
!define MUI_FINISHPAGE_RUN_FUNCTION OpenDiscord
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

!macro CloseApp EXE
    ${IfNot} $TestMode == 1
        nsExec::Exec 'taskkill /F /T /IM ${EXE}'
        Pop $0
        ${If} $0 == 0
            Sleep 2000
        ${EndIf}
    ${EndIf}
!macroend

; Sets $Cmp to 1 when $Res holds a stub that loads Moss.
!macro DefineIsMoss UN STRSTR
Function ${UN}IsMoss
    StrCpy $Cmp 0
    ${If} ${FileExists} "$Res\app.asar\index.js"
        StrCpy $1 "$Res\app.asar\index.js"
    ${ElseIf} ${FileExists} "$Res\app\index.js"
        StrCpy $1 "$Res\app\index.js"
    ${Else}
        Return
    ${EndIf}
    ClearErrors
    FileOpen $0 $1 r
    ${IfNot} ${Errors}
        FileRead $0 $Line
        FileClose $0
        ${STRSTR} $2 $Line "${DIRNAME}"
        ${If} $2 != ""
            StrCpy $Cmp 1
        ${EndIf}
    ${EndIf}
FunctionEnd
!macroend
!insertmacro DefineIsMoss "" "${StrStr}"
!insertmacro DefineIsMoss "un." "${UnStrStr}"

; Puts Discord's own app.asar back in $Res, whichever mod's shim is there.
!macro DefineRestore UN
Function ${UN}RestoreVanilla
    ${If} ${FileExists} "$Res\betterdiscord.app.asar"
        Delete "$Res\app\index.js"
        Delete "$Res\app\package.json"
        RMDir "$Res\app"
        Rename "$Res\betterdiscord.app.asar" "$Res\app.asar"
    ${ElseIf} ${FileExists} "$Res\_app.asar"
        Delete "$Res\app.asar\index.js"
        Delete "$Res\app.asar\package.json"
        RMDir "$Res\app.asar"
        Delete "$Res\app\index.js"
        Delete "$Res\app\package.json"
        RMDir "$Res\app"
        Rename "$Res\_app.asar" "$Res\app.asar"
    ${EndIf}
FunctionEnd
!macroend
!insertmacro DefineRestore ""
!insertmacro DefineRestore "un."

Section "-Moss" SecCore
    SetOutPath "$INSTDIR"
    File "/oname=moss.asar" "${ASAR}"
    WriteUninstaller "$INSTDIR\${UNINSTALLER}"
    ${IfNot} $TestMode == 1
        WriteRegStr HKCU "${UNINST_KEY}" "DisplayName" "${NAME}"
        WriteRegStr HKCU "${UNINST_KEY}" "DisplayVersion" "${VERSION}"
        WriteRegStr HKCU "${UNINST_KEY}" "Publisher" "departin"
        WriteRegStr HKCU "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\${UNINSTALLER}"
        WriteRegStr HKCU "${UNINST_KEY}" "UninstallString" '"$INSTDIR\${UNINSTALLER}"'
        WriteRegStr HKCU "${UNINST_KEY}" "QuietUninstallString" '"$INSTDIR\${UNINSTALLER}" /S'
        WriteRegDWORD HKCU "${UNINST_KEY}" "NoModify" 1
        WriteRegDWORD HKCU "${UNINST_KEY}" "NoRepair" 1
        ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
        WriteRegDWORD HKCU "${UNINST_KEY}" "EstimatedSize" $0
    ${EndIf}
SectionEnd

Section "Discord" SecStable
    !insertmacro CloseApp "Discord.exe"
    StrCpy $PRoot $Root
    Call PatchRoot
SectionEnd

Section /o "Discord PTB" SecPtb
    !insertmacro CloseApp "DiscordPTB.exe"
    StrCpy $PRoot "$LOCALAPPDATA\DiscordPTB"
    Call PatchRoot
SectionEnd

Section /o "Discord Canary" SecCanary
    !insertmacro CloseApp "DiscordCanary.exe"
    StrCpy $PRoot "$LOCALAPPDATA\DiscordCanary"
    Call PatchRoot
SectionEnd

; Sets $Newest to the newest app-* folder in $PRoot, or "" if there is none.
Function FindNewest
    StrCpy $Newest ""
    FindFirst $Find $FindName "$PRoot\app-*"
    ${DoWhile} $FindName != ""
        ${If} ${FileExists} "$PRoot\$FindName\resources\*.*"
            ${If} $Newest == ""
                StrCpy $Newest $FindName
            ${Else}
                StrCpy $0 $FindName "" 4
                StrCpy $1 $Newest "" 4
                ${VersionCompare} $0 $1 $2
                ${If} $2 == 1
                    StrCpy $Newest $FindName
                ${EndIf}
            ${EndIf}
        ${EndIf}
        FindNext $Find $FindName
    ${Loop}
    FindClose $Find
FunctionEnd

Function WriteStub
    CreateDirectory "$Res\app.asar"
    FileOpen $0 "$Res\app.asar\package.json" w
    FileWrite $0 '{"name":"discord","main":"index.js"}'
    FileClose $0
    FileOpen $0 "$Res\app.asar\index.js" w
    FileWrite $0 '${STUB}'
    FileClose $0
FunctionEnd

Function PatchRoot
    Call FindNewest
    ${If} $Newest == ""
        DetailPrint "No Discord version found in $PRoot"
        Return
    ${EndIf}
    StrCpy $Res "$PRoot\$Newest\resources"

    Call IsMoss
    ${If} $Cmp == 1
        DetailPrint "Moss is already in $Newest, refreshing it"
        Call RestoreVanilla
    ${ElseIf} ${FileExists} "$Res\betterdiscord.app.asar"
        MessageBox MB_ICONQUESTION|MB_YESNO "BetterDiscord is installed in this Discord app ($PRoot). Two mods can't run at once.$\r$\n$\r$\nReplace BetterDiscord with Moss? Your BetterDiscord plugins and settings stay where they are, so you can reinstall it later." /SD IDYES IDYES +3
        DetailPrint "Skipped $PRoot, BetterDiscord kept"
        Return
        Call RestoreVanilla
    ${ElseIf} ${FileExists} "$Res\_app.asar"
        MessageBox MB_ICONQUESTION|MB_YESNO "Another Discord mod (like Vencord or Equicord) is installed in this Discord app ($PRoot). Two mods can't run at once.$\r$\n$\r$\nReplace it with Moss?" /SD IDYES IDYES +3
        DetailPrint "Skipped $PRoot, the other mod was kept"
        Return
        Call RestoreVanilla
    ${EndIf}

    ${IfNot} ${FileExists} "$Res\app.asar"
        MessageBox MB_ICONSTOP|MB_OK "Couldn't find Discord's files in $Res. Reinstall Discord and try again." /SD IDOK
        Return
    ${EndIf}
    ClearErrors
    Rename "$Res\app.asar" "$Res\_app.asar"
    ${If} ${Errors}
        MessageBox MB_ICONSTOP|MB_OK "Couldn't add Moss because Discord's files are in use. Quit Discord from the tray icon and run this setup again." /SD IDOK
        Return
    ${EndIf}
    Call WriteStub
    DetailPrint "Added Moss to $PRoot\$Newest"
FunctionEnd

Function OpenDiscord
    ${If} $TestMode != 1
    ${AndIf} ${FileExists} "$Root\Update.exe"
        Exec '"$Root\Update.exe" --processStart Discord.exe'
    ${EndIf}
FunctionEnd

!macro ReadRoot
    StrCpy $Root "$LOCALAPPDATA\Discord"
    StrCpy $TestMode 0
    ${GetParameters} $0
    ClearErrors
    ${GetOptions} $0 "/ROOT=" $1
    ${IfNot} ${Errors}
        StrCpy $Root $1
        StrCpy $TestMode 1
    ${EndIf}
!macroend

Function .onInit
    !insertmacro ReadRoot
    StrCpy $Opened 0
    ${If} ${FileExists} "$Root\*.*"
        IntOp $Opened $Opened + 1
    ${Else}
        !insertmacro UnselectSection ${SecStable}
        !insertmacro SetSectionFlag ${SecStable} ${SF_RO}
    ${EndIf}
    ${If} ${FileExists} "$LOCALAPPDATA\DiscordPTB\*.*"
    ${AndIf} $TestMode != 1
        IntOp $Opened $Opened + 1
    ${Else}
        !insertmacro SetSectionFlag ${SecPtb} ${SF_RO}
    ${EndIf}
    ${If} ${FileExists} "$LOCALAPPDATA\DiscordCanary\*.*"
    ${AndIf} $TestMode != 1
        IntOp $Opened $Opened + 1
    ${Else}
        !insertmacro SetSectionFlag ${SecCanary} ${SF_RO}
    ${EndIf}
    ${If} $Opened == 0
        MessageBox MB_ICONSTOP|MB_OK "Moss couldn't find Discord on this PC. Install Discord first, or use the standalone Moss app instead." /SD IDOK
        Abort
    ${EndIf}
FunctionEnd

Function un.onInit
    !insertmacro ReadRoot
FunctionEnd

Function un.UnpatchRoot
    FindFirst $Find $FindName "$PRoot\app-*"
    ${DoWhile} $FindName != ""
        StrCpy $Res "$PRoot\$FindName\resources"
        Call un.IsMoss
        ${If} $Cmp == 1
            Call un.RestoreVanilla
            DetailPrint "Removed Moss from $FindName"
        ${EndIf}
        FindNext $Find $FindName
    ${Loop}
    FindClose $Find
FunctionEnd

Section "Uninstall"
    !insertmacro CloseApp "Discord.exe"
    !insertmacro CloseApp "DiscordPTB.exe"
    !insertmacro CloseApp "DiscordCanary.exe"
    StrCpy $PRoot $Root
    Call un.UnpatchRoot
    ${If} $TestMode != 1
        StrCpy $PRoot "$LOCALAPPDATA\DiscordPTB"
        Call un.UnpatchRoot
        StrCpy $PRoot "$LOCALAPPDATA\DiscordCanary"
        Call un.UnpatchRoot
        DeleteRegKey HKCU "${UNINST_KEY}"
    ${EndIf}
    Delete "$INSTDIR\moss.asar"
    Delete "$INSTDIR\${UNINSTALLER}"
    RMDir "$INSTDIR"
SectionEnd
