; Tusab installer
;
; TO do:
; - Fix EnVar 1024 character limit when adding paths to Path variable
; - Figure out how to add spaces to backup and sync config file path
; - Find better way of downloading 3rd party software (weithout using URLs that can change)
; - Add functionality to prevent user from finishing setup without logging in to B&S
;    - Once this is implemented, automatically launch tusabgui on completion
; - Add shortcut to desktop section

;--------------------------------

; The name of the installer
Name "Tusab Installer"

; The file to write
OutFile "tusabinstaller.exe"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir C:\Tusab

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM SOFTWARE\Tusab "InstallPath"

;--------------------------------

; Pages

Page license
Page components
Page directory "" "" stayInPath
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------


!define StrRep "!insertmacro StrRep"
!macro StrRep output string old new
    Push `${string}`
    Push `${old}`
    Push `${new}`
    !ifdef __UNINSTALL__
        Call un.StrRep
    !else
        Call StrRep
    !endif
    Pop ${output}
!macroend
 
!macro Func_StrRep un
    Function ${un}StrRep
        Exch $R2 ;new
        Exch 1
        Exch $R1 ;old
        Exch 2
        Exch $R0 ;string
        Push $R3
        Push $R4
        Push $R5
        Push $R6
        Push $R7
        Push $R8
        Push $R9
 
        StrCpy $R3 0
        StrLen $R4 $R1
        StrLen $R6 $R0
        StrLen $R9 $R2
        loop:
            StrCpy $R5 $R0 $R4 $R3
            StrCmp $R5 $R1 found
            StrCmp $R3 $R6 done
            IntOp $R3 $R3 + 1 ;move offset by 1 to check the next character
            Goto loop
        found:
            StrCpy $R5 $R0 $R3
            IntOp $R8 $R3 + $R4
            StrCpy $R7 $R0 "" $R8
            StrCpy $R0 $R5$R2$R7
            StrLen $R6 $R0
            IntOp $R3 $R3 + $R9 ;move offset by length of the replacement string
            Goto loop
        done:
 
        Pop $R9
        Pop $R8
        Pop $R7
        Pop $R6
        Pop $R5
        Pop $R4
        Pop $R3
        Push $R0
        Push $R1
        Pop $R0
        Pop $R1
        Pop $R0
        Pop $R2
        Exch $R1
    FunctionEnd
!macroend
!insertmacro Func_StrRep ""
!insertmacro Func_StrRep "un."


; StrContains
; This function does a case sensitive searches for an occurrence of a substring in a string. 
; It returns the substring if it is found. 
; Otherwise it returns null(""). 
; Written by kenglish_hi
; Adapted from StrReplace written by dandaman32
 
 
Var STR_HAYSTACK
Var STR_NEEDLE
Var STR_CONTAINS_VAR_1
Var STR_CONTAINS_VAR_2
Var STR_CONTAINS_VAR_3
Var STR_CONTAINS_VAR_4
Var STR_RETURN_VAR
 
Function StrContains
  Exch $STR_NEEDLE
  Exch 1
  Exch $STR_HAYSTACK
  ; Uncomment to debug
  ;MessageBox MB_OK 'STR_NEEDLE = $STR_NEEDLE STR_HAYSTACK = $STR_HAYSTACK '
    StrCpy $STR_RETURN_VAR ""
    StrCpy $STR_CONTAINS_VAR_1 -1
    StrLen $STR_CONTAINS_VAR_2 $STR_NEEDLE
    StrLen $STR_CONTAINS_VAR_4 $STR_HAYSTACK
    loop:
      IntOp $STR_CONTAINS_VAR_1 $STR_CONTAINS_VAR_1 + 1
      StrCpy $STR_CONTAINS_VAR_3 $STR_HAYSTACK $STR_CONTAINS_VAR_2 $STR_CONTAINS_VAR_1
      StrCmp $STR_CONTAINS_VAR_3 $STR_NEEDLE found
      StrCmp $STR_CONTAINS_VAR_1 $STR_CONTAINS_VAR_4 done
      Goto loop
    found:
      StrCpy $STR_RETURN_VAR $STR_NEEDLE
      Goto done
    done:
   Pop $STR_NEEDLE ;Prevent "invalid opcode" errors and keep the
   Exch $STR_RETURN_VAR  
FunctionEnd
 
!macro _StrContainsConstructor OUT NEEDLE HAYSTACK
  Push `${HAYSTACK}`
  Push `${NEEDLE}`
  Call StrContains
  Pop `${OUT}`
!macroend
 
!define StrContains '!insertmacro "_StrContainsConstructor"'


Function stayInPath
	${StrContains} $0 " " "$INSTDIR"
	StrCmp $0 "" stayInPath_exit
		MessageBox MB_OK "Please chose a location with no spaces"
		Abort
stayInPath_exit:

FunctionEnd


Function WriteToFileLine
	Exch $0 ;file
	Exch
	Exch $1 ;line number
	Exch 2
	Exch $2 ;string to write
	Exch 2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
		 
		 GetTempFileName $7
		 FileOpen $4 $0 r
		 FileOpen $5 $7 w
		 StrCpy $3 0
	 
	Loop:
	ClearErrors
	FileRead $4 $6
	IfErrors Exit
		 IntOp $3 $3 + 1
		 StrCmp $3 $1 0 +3
	;FileWrite $5 "$2$\r$\n$6" # THIS CODE ADD NEW TEXT IN LINE x WITHOUT REMOVING OLD TEXT INSTED ADD OLD TEXT IN NEW LINE
	FileWrite $5 "$2$\r$\n"   # THIS WAY WILL REPLACE LINE x WITHOUT ADDING OLD TEXT IN NEW LINE 
	Goto Loop
	FileWrite $5 $6
	Goto Loop
	Exit:
	 
	 FileClose $5
	 FileClose $4
	 
	SetDetailsPrint none
	Delete $0
	Rename $7 $0
	SetDetailsPrint both
	 
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; The stuff to install
Section "Tusab (required)" ;No components page, name is not important

	SectionIn RO

	CreateDirectory $INSTDIR\tusab-cmd
	CreateDirectory $INSTDIR\tusab-gui
	CreateDirectory $INSTDIR\b2b
	CreateDirectory $INSTDIR\bns
	CreateDirectory $INSTDIR\tmp

  	; Set output path to tusab-cmd
  	SetOutPath $INSTDIR\tusab-cmd
  
  	; Put tusab.exe files there
  	File /r "E:\Software Projects\Python\tusab\dist\main\*"

  	; delete the config.json from \dist\main as it containt user credentials
  	Delete $INSTDIR\tusab-cmd\config.json

  	; Copy correct, 'new' config.json
  	File ".\config.json"

  	; Add tmp path
  	Push '    "temporary-file-path": "$INSTDIR\tmp",'
  	Push "\"
  	Push "\\"
  	Call StrRep
  	Push 2
  	Push "$INSTDIR\tusab-cmd\config.json"
  	Call WriteToFileLine

  	; Add backup and sync path
  	Push '    "backup-and-sync-path": "$INSTDIR\bns",'
  	Push "\"
  	Push "\\"
  	Call StrRep
  	Push 3
  	Push "$INSTDIR\tusab-cmd\config.json"
  	Call WriteToFileLine

  	; Set output path to b2b
  	SetOutPath $INSTDIR\b2b

  	; Install B2B
  	File "E:\Software Projects\Geany\b2b\bin\b2b.exe"

  	; Install .NET framework here (Or ask user to install it) Or call Visual Studio installer

  	; Set output path to tusab gui
  	SetOutPath $INSTDIR\tusab-gui

  	; COpy tusab gui files
  	File /r "E:\Software Projects\Visual Studio 2019\TUSABgui\bin\Debug\*"

  	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INSTALL 7Z

  	; Test to see if 7zip is already installed
  	ReadRegStr $0 HKLM "Software\7-Zip" "Path"

  	StrCmp $0 "" 0 szip_is_installed

  		DetailPrint "7-Zip not found, preparing to install..."
  		
  		; Download 32-bit 7zip installer
  		inetc::get "https://www.7-zip.org/a/7z1900.exe" "7zsetup.exe"

	  	; Execute installer
	  	ExecWait "$INSTDIR\tusab-gui\7zsetup.exe"

  	; Make sure 7zip is installed (check registry for installation path, then check path for presence of 7z.exe) if not, abort
  	DetailPrint "Locating 7zip installation directory..."

  	ReadRegStr $0 HKLM "Software\7-Zip" "Path"

  	StrCmp $0 "" 0 szip_is_installed
  		MessageBox MB_OK "7Zip was not installed correctly. Aborting..."
  		Abort

  	szip_is_installed:

  	; Make sure 7z.exe exists 
  	DetailPrint "Locating 7z.exe... ($07z.exe)"

  	IfFileExists "$07z.exe" szip_exe_found 0
  		MessageBox MB_OK "7Zip was not installed correctly. Aborting..."
  		Abort

  	szip_exe_found:
  	
  	DetailPrint "Deleting 7zip installer..."

  	; Delete 7zsetup.exe
  	Delete "$INSTDIR\tusab-gui\7zsetup.exe"

  	; Add 7z installation path to PATH
  	EnVar::AddValue "Path" "$0"

  	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INSTALL MAGICk

  	; Test to see if magick is already installed
  	SetRegView 64
  	ReadRegStr $0 HKLM "Software\ImageMagick\Current" "BinPath"

  	DetailPrint "Magick bin path: '$0'"

  	StrCmp $0 "" 0 magick_is_installed

  		DetailPrint "Magick not found, preparing to install..."
  		
  		; Download 32-bit magick installer
  		inetc::get "https://imagemagick.org/download/binaries/ImageMagick-7.0.10-37-Q16-HDRI-x64-dll.exe" "magicksetup.exe"

	  	; Execute installer
	  	ExecWait "$INSTDIR\tusab-gui\magicksetup.exe"

	  	; Delete magicksetup.exe
	  	Delete "$INSTDIR\tusab-gui\magicksetup.exe"

  	; Make sure magick is installed (check registry for installation path, then check path for presence of magick.exe) if not, abort
  	DetailPrint "Locating magick installation directory..."

  	ReadRegStr $0 HKLM "Software\ImageMagick\Current" "BinPath"

  	StrCmp $0 "" 0 magick_is_installed
  		MessageBox MB_OK "ImageMagick was not installed correctly. Aborting..."
  		Abort

  	magick_is_installed:

  	; Make sure magick.exe exists 
  	DetailPrint "Locating magick.exe..."

  	IfFileExists "$0\magick.exe" magick_exe_found 0
  		MessageBox MB_OK "Magick was not installed correctly. Aborting..."
  		Abort

  	magick_exe_found:
  	
  	DetailPrint "Deleting magick installer..."

  	; If b&s is installed, uninstall it
  	ReadRegStr $0 HKLM "Software\Google\Drive" "InstallLocation"

  	SetRegView 32

  	DetailPrint "Google Drive registry entry - '$0'"

  	StrCmp $0 "" install_bns
  		MessageBox MB_YESNO "Tusab installer has detected a version of Backup and Sync already installed. Due to the way Tusab operates, this must be removed and reinstalled with different settings. Would you like to proceed?" IDYES install_bns
  		MessageBox MB_OK "Aborting installer..."
  		Abort

  	install_bns:

  	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Install b&s

  	; Copy config thing
  	CreateDirectory "$LOCALAPPDATA\Google\Drive\user_default"
  	SetOutPath "$LOCALAPPDATA\Google\Drive\user_default"
  	File ".\user_setup.config"

  	; Modify user_setup.config file
  	Push "folders: $INSTDIR\bns"
  	Push 7
  	Push "$LOCALAPPDATA\Google\Drive\user_default\user_setup.config"
  	Call WriteToFileLine

  	; Download B&S installer
  	SetOutPath $INSTDIR\bns

  	File ".\installbackupandsync.exe"

  	; Execute installer
  	ExecWait "$INSTDIR\bns\installbackupandsync.exe"

  	; Delete installer
  	Delete "$INSTDIR\bns\installbackupandsync.exe"

  	; Add b2b installation path to PATH
  	EnVar::AddValue "Path" "$INSTDIR\b2b"

  	; Add tusab-cmd to path
  	EnVar::AddValue "Path" "$INSTDIR\tusab-cmd"

  	; Add registry values
  	WriteRegStr HKLM SOFTWARE\Tusab "InstallPath" "$INSTDIR"

  	; Write uninstaller
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Tusab" "DisplayName" "Tusab"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Tusab" "UninstallString" '"$INSTDIR\uninstall.exe"'
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Tusab" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Tusab" "NoRepair" 1
  	WriteUninstaller "$INSTDIR\uninstall.exe"

  
SectionEnd ; end the section

Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\Tusab"
  CreateShortcut "$SMPROGRAMS\Tusab\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  CreateShortcut "$SMPROGRAMS\Tusab\TusabGUI.lnk" "$INSTDIR\tusab-gui\TUSABgui.exe"

SectionEnd

Section "Add to context menu"



SectionEnd

Section "Add desktop shortcut"
	CreateShortcut "$DESKTOP\TusabGUI.lnk" "$INSTDIR\tusab-gui\TUSABgui.exe"
SectionEnd

Section "Uninstall"

 	; We do not remove third part tools, as they may be used by other applications

	; Delete b2b and tusab-cmd path entries
	EnVar::DeleteValue "Path" "$INSTDIR\b2b"
	EnVar::DeleteValue "Path" "$INSTDIR\tusab-cmd"

	; Delete installation directory
	RMDir /r "$INSTDIR"
	RMDir "$SMPROGRAMS\Tusab"

	; Remove tusab gui reg entry
	DeleteRegKey HKLM SOFTWARE\Tusab
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Tusab"

	; Uninstall B&S, which was installed specifically for tusab 

	; Remove entry from context menu if present

	; Remove desktop shortcut
	Delete "$DESKTOP\TusabGUI.lnk"

SectionEnd
