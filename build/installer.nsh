!include nsDialogs.nsh
!include LogicLib.nsh

!define MOSS_RUN_KEY "Software\Microsoft\Windows\CurrentVersion\Run"
!define MOSS_APPROVED_KEY "Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
!define MOSS_RUN_NAME "app.moss.client"

!macro preInit
 SetRegView 64
  WriteRegExpandStr HKLM "${INSTALL_REGISTRY_KEY}" InstallLocation "$LocalAppData\Programs\Moss"
  WriteRegExpandStr HKCU "${INSTALL_REGISTRY_KEY}" InstallLocation "$LocalAppData\Programs\Moss"
 SetRegView 32
  WriteRegExpandStr HKLM "${INSTALL_REGISTRY_KEY}" InstallLocation "$LocalAppData\Programs\Moss"
  WriteRegExpandStr HKCU "${INSTALL_REGISTRY_KEY}" InstallLocation "$LocalAppData\Programs\Moss"
!macroend

!ifndef BUILD_UNINSTALLER
  Var MossAutoStart
  Var MossNoDiscord
  Var MossAutoStartBox
  Var MossNoDiscordBox

  !macro customPageAfterChangeDir
    Page custom MossStartupPage MossStartupLeave
  !macroend

  Function MossStartupPage
    nsDialogs::Create 1018
    Pop $0
    ${NSD_CreateLabel} 0 0 100% 20u "Moss can open by itself when you sign in, so it's ready when you are."
    Pop $0
    ${NSD_CreateCheckbox} 0 30u 100% 12u "Start Moss when Windows starts"
    Pop $MossAutoStartBox
    ${NSD_Check} $MossAutoStartBox
    ${NSD_CreateCheckbox} 0 52u 100% 12u "Stop the regular Discord app from starting with Windows"
    Pop $MossNoDiscordBox
    ${NSD_Check} $MossNoDiscordBox
    ${NSD_CreateLabel} 12u 66u 95% 30u "So only Moss opens at startup. You can turn Discord back on any time in Task Manager, under Startup apps, and uninstalling Moss turns it back on for you."
    Pop $0
    nsDialogs::Show
  FunctionEnd

  Function MossStartupLeave
    ${NSD_GetState} $MossAutoStartBox $MossAutoStart
    ${NSD_GetState} $MossNoDiscordBox $MossNoDiscord
  FunctionEnd

  !macro customInstall
    ${IfNot} ${isUpdated}
      ; silent installs skip the page
      ${If} $MossAutoStart == ""
        StrCpy $MossAutoStart ${BST_CHECKED}
        StrCpy $MossNoDiscord ${BST_CHECKED}
      ${EndIf}
      ${If} $MossAutoStart == ${BST_CHECKED}
        WriteRegStr HKCU "${MOSS_RUN_KEY}" "${MOSS_RUN_NAME}" '"$INSTDIR\${APP_EXECUTABLE_FILENAME}"'
      ${EndIf}
      ${If} $MossNoDiscord == ${BST_CHECKED}
        ReadRegStr $0 HKCU "${MOSS_RUN_KEY}" "Discord"
        ${If} $0 != ""
          WriteRegBin HKCU "${MOSS_APPROVED_KEY}" "Discord" 030000000000000000000000
          WriteRegStr HKCU "Software\Moss" "DisabledDiscordStartup" "1"
        ${EndIf}
      ${EndIf}
    ${EndIf}
  !macroend
!endif

!macro customUnInstall
  ${IfNot} ${isUpdated}
    DeleteRegValue HKCU "${MOSS_RUN_KEY}" "${MOSS_RUN_NAME}"
    ReadRegStr $0 HKCU "Software\Moss" "DisabledDiscordStartup"
    ${If} $0 == "1"
      WriteRegBin HKCU "${MOSS_APPROVED_KEY}" "Discord" 020000000000000000000000
    ${EndIf}
    DeleteRegKey HKCU "Software\Moss"
  ${EndIf}
!macroend
