
 ; Copyright (c) 2017 ootsby <ootsby@gmail.com>
 ; 
 ; Permission is hereby granted, free of charge, to any person obtaining
 ; a copy of this software and associated documentation files (the
 ; "Software"), to deal in the Software without restriction, including
 ; without limitation the rights to use, copy, modify, merge, publish,
 ; distribute, sublicense, and/or sell copies of the Software, and to
 ; permit persons to whom the Software is furnished to do so, subject to
 ; the following conditions:
 ; 
 ; The above copyright notice and this permission notice shall be
 ; included in all copies or substantial portions of the Software.
 ; 
 ; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 ; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 ; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 ; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 ; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 ; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 ; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 

#Include %A_ScriptDir%\lib\AHKsock\AHKsock.ahk
#SingleInstance force
#NoEnv
#InstallKeybdHook
#InstallMouseHook
#MaxHotKeysPerInterval 10000

programName := "CKS-E"
APP_VERSION := "0.3.1-alpha"

OutputIntervalBaseList := "0.2|0.3|0.4|0.5|0.75|1|1.5|2|3|4|5|10"
KeypressIntervalBaseList := "0.1|0.2|0.3|0.4|0.5|0.6|0.7|0.8|0.9|1.0"


Gui Margin, 10, 10
Gui Add, CheckBox, xm ym w130 h20 vMouseEnabled gMouseToggle, Listen to mouse
Gui Add, CheckBox, xp y+5 w130 h20 vKbdEnabled gKbdToggle, Listen to keyboard
Gui Add, CheckBox, xp y+5 w130 h20 vPhsEnabled gPhsToggle, Listen to user input
Gui Add, CheckBox, xp y+5 w130 h20 vJoypadEnabled gJoypadToggle, Listen to joypad

Gui Add, CheckBox,  ym w130 h20 vBlockOutput gBlockOutputToggle, Block If In Window
Gui Add, CheckBox,  y+5 w130 h20 vMimic gMimicToggle, Mirror Keys
Gui Add, CheckBox,  y+5 w130 h20 vBlank1 hidden, Spacer 
Gui Add, CheckBox,  y+5 w130 h20 vServerModeEnabled gServerModeUpdated, Act As Server
Gui Add, Button,  y+3 w130 h21 vConnectText gConnectButton, Connect

Gui Add, CheckBox,  ym w130 h20 vSequenceEnabled, Send In Sequence
Gui Add, CheckBox,  y+5 w130 h20 vKeypressEmulationEnabled gKeypressEmuToggle, Emulate Key Down/Up
Gui Add, CheckBox,  y+5 w130 h20 vBlank2 hidden, Spacer 
Gui Add, Text,  y+8 w130 h20 +center, Server IP
Gui Add, Edit,  y+0 w130 h21 vServerIP gServerIPUpdated +center, %A_IPAddress1%

Gui Add, Text,  ym+3 w90 h20 +right, Keys to Send
Gui Add, Text,  y+5 w90 h20 +right, Output Interval
Gui Add, Text,  y+5 w90 h20 +right, Keypress Length
Gui Add, Text,  y+5 w60 h20 +center, Port
Gui Add, Edit,  y+0 w60 h21 vServerPort gServerPortUpdated +center, 29999

Gui Add, Edit,  ym w130 h21 vKeys +0x200, 1
Gui Add, ComboBox,  y+4 w60 vCBOutputIntervalLow gIntervalsUpdated, %OutputIntervalBaseList%
Gui Add, Text, x+2 yp w3 h21 vCBOutputIntervalLowError cRed hidden, !
Gui Add, ComboBox, xp-62 y+4 w60 vCBKeypressLengthLow gIntervalsUpdated, %KeypressIntervalBaseList%
Gui Add, Text, x+2 yp w3 h21 vCBOutputIntervalHighError cRed hidden, !
Gui Add, Text, xp-62 y+7 w60 h20 +center, Pause Key
Gui Add, Edit, xp y+0 w60 h21 vPauseKey gPauseKeyChanged +0x201, #p

Gui Add, ComboBox, x+10 yp-73 w60 vCBOutputIntervalHigh gIntervalsUpdated, %OutputIntervalBaseList%
Gui Add, Text, x+2 yp w3 h21 vCBKeypressLengthLowError cRed hidden, !
Gui Add, ComboBox, xp-62 y+4 w60 vCBKeypressLengthHigh gIntervalsUpdated, %KeypressIntervalBaseList%
Gui Add, Text, x+2 yp w3 h21 vCBKeypressLengthHighError cRed hidden, !

Gui Add, Button, xp-62 y+4 w61 h42 vApplyIntervals gApplyIntervals Disabled, Apply Intervals

Gui Add, Button,  xm y+15 w120 h22 gRefreshList, Refresh
Gui Add, Text, x+0 yp+1 w411 h20 vAppStatus +Center +Border +0x201, Status Line
Gui Add, Button,  x+0 yp-1 w120 h22 vPauseButton gPauseListen, Pause


Gui, Add, ListView, xm y+10 w651 h400 vProgramList gProgramList Checked Sort, Name|Class|ID

Menu, FileMenu, Add, Load Profile, LoadProfile
Menu, FileMenu, Add, Save Profile, SaveProfile
Menu, HelpMenu, Add, Usage, HelpListen	
Menu, HelpMenu, Add, About, AboutBox
Menu, MyMenuBar, Add, &File, :FileMenu
Menu, MyMenuBar, Add, &Help, :HelpMenu
Gui, Menu, MyMenuBar

DefaultConfigFile := "CKS-E_Defaults.ini"

CoordMode, Mouse, Screen

If A_IsCompiled
  Menu, Tray, Icon, %A_ScriptFullPath%, -159

;Set up an error handler (this is optional)
AHKsock_ErrorHandler("AHKsockErrors")
    
;Set up an OnExit routine
;OnExit, GuiClose

;Set default value to invalid handle
iPeerSocket := -1


idList := object()
Refresh(idList)
Seq := 0
Timer := 0
NextAllowedOutputTime := 0
IsPaused := False
IsListening := False
IsConnected := False
IsConnecting := False
clientSocket := -1
windowName = %programName% %APP_VERSION%

Gui, Submit, NoHide
Gui, Show,, %windowName%

If( !FileExist(DefaultConfigFile)  ){
    MsgBox,, First Time Use, It looks like you're using CKS-E for the first time. Setting some defaults. Please read the help to get started."
	
	GuiControl,, CBOutputIntervalLow, 0.5||
	GuiControl,, CBOutputIntervalHigh, 1.0||
	GuiControl,, CBKeypressLengthLow, 0.3||
	GuiControl,, CBKeypressLengthHigh, 0.6||
	GuiControl,, PauseKey, #p
	ApplyIntervals()
}Else{
	LoadConfig( DefaultConfigFile )
}

OldPause := PauseKey
Hotkey, %PauseKey%, PauseListen

JoyPadAxes := Object()
Return

LoadProfile(){
	FileSelectFile, SelectedFile, 3, , Open a file, ini files (*.ini)
	If( SelectedFile <> "" ){
		LoadConfig(SelectedFile)
	}
}

SaveProfile(){
	FileSelectFile, SelectedFile, S, , Save To File, ini files (*.ini)
	If( SelectedFile <> "" ){
		SaveConfig(SelectedFile)
	}
}

SetJoyPadListening( OnOrOff ){
	Global JoyPadAxes
	
	If( OnOrOff = "Off" ){
		JoyPadAxes := Object()
	}
	
	Loop 16 {
		InputPrefix = %A_Index%Joy
		
		GetKeyState, JoyName, %InputPrefix%Name
        
		if JoyName <>
        {
			GetKeyState, NumButtons, %InputPrefix%Buttons
		
			Loop %NumButtons% {
				Hotkey, %InputPrefix%%A_Index%, OnJoyPadKey, %OnOrOff%
			}
			
			If( OnOrOff = "On" ){
				GetKeyState, Info, %InputPrefix%JoyInfo
			
				axes := Object()
				axes["X"] := 0
				axes["Y"] := 0
				
				If( InStr(%Info%, Z) ){
					axes["Z"] := 0
				}
				If( InStr(%Info%, R) ){
					axes["R"] := 0
				}
				If( InStr(%Info%, U) ){
					axes["U"] := 0
				}
				If( InStr(%Info%, V) ){
					axes["V"] := 0
				}
				If( InStr(%Info%, P) ){
					axes["POV"] := 0
				}
			
				JoyPadAxes[InputPrefix] := axes
			}
		}
	}
}

OnJoyPadKey(){
	Global
	sendKeys(Keys, Seq++, SequenceEnabled)
}

GuiClose(){
    
    ;So that we don't go back to listening on disconnect
    bExiting := True
    
    /*! If the GUI is closed, this function will be called twice:
        - Once non-critically when the GUI event fires (GuiEscape or GuiClose) (graceful shutdown will occur), and
        - Once more critically during the OnExit sub (after the previous GUI event calls ExitApp)
        
        But if the application is exited using the Exit item in the tray's menu, graceful shutdown will be impossible
        because AHKsock_Close() will only be called once critically during the OnExit sub.
    */
    AHKsock_Close()
	FinaliseAndExit()
	ExitApp
}

MenuHandler(){
	Return
}

PauseKeyChanged(){
	Gui submit, NoHide
	if (OldPause = PauseKey)
		Return

	if (OldPause != "") {
		Hotkey, %OldPause%, Off
	}

	if (PauseKey = "" )
		Return

	Hotkey, %PauseKey%, PauseListen
	OldPause := PauseKey
	Return
}

CoordsListen(){
	if (Timer) {
		Settimer WatchCursor, off
		Tooltip
		Timer:=0
	} else {
		Settimer WatchCursor, 50
		Timer:=1
	}
	Return
}

WatchCursor(){
	MouseGetPos , mouseX, mouseY
	ToolTip, %mouseX% %mouseY%
	Return
}

KbdToggle(){
	Global KbdEnabled
	
	Gui, Submit, NoHide
	
	if( KbdEnabled ){
		SetTimer, KbdListen, -0
	}
	Return
}

KeypressEmuToggle(){
	Gui, Submit, NoHide
}

BlockOutputToggle(){
	Gui, Submit, NoHide
}

MimicToggle(){
	Gui, Submit, NoHide
}

KbdListen(){
	Global
	
	while (KbdEnabled)
	{
		Input, SingleKey, L1 V,  {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{Backspace}{Capslock}{Numlock}{PrintScreen}{Pause}
		
		if (Mimic)
			sendkeys(SingleKey, Seq++, SequenceEnabled)
		else
			sendKeys(Keys, Seq++, SequenceEnabled)
	}
	Return
}

PhsToggle(){
	Global PhsEnabled
	
	Gui, Submit, NoHide
	
	if( PhsEnabled ){
		SetTimer, PhsListen, -0
	}
	Return
}

PhsListen(){
	Global PhsEnabled
	
	DetectPeriod := 50
	
	If(PhsEnabled){
		if (A_TimeIdlePhysical < 50){ 
			doSend()
		}
		SetTimer, , -50
	}Else{
		SetTimer, , Off
	}
}

PauseListen(){
	Global
	If( IsPaused ){
	   IsPaused := False
	   GuiControl,, PauseButton, Pause
	}Else{
		IsPaused := True
		GuiControl,, PauseButton, Unpause
	}
}

AboutBox(){
	Global
	
	txtVar := Format("CKS-E version {1}`n`nCKS-E is a tool that can be configured to listen for various user inputs and send keypresses to one or more applications on your PC based on that input. For example, CKS-E could allow you to send a key to perform repetitive crafting actions on an MMO character when you move your mouse while photo-editing, for each key you press while you type a report or when you use your joypad when playing another game. `n`nHomepage: https://github.com/ootsby/CKS-E`n`nCKS-E is based on the Consortium Key Sender by Pliaksi:`n http://stormspire.net/tools-programs-and-spreadsheets/3828-consortium-key-sender-cks.html`n`nCKS-E uses AHKSock by TheGood:`n https://autohotkey.com/board/topic/53827-ahksock-a-simple-ahk-implementation-of-winsock-tcpip/", APP_VERSION)
	
	msgbox ,,About, %txtVar%
	Return
}

HelpListen(){
	txtVar := "Err... Look at the homepage for now: https://github.com/ootsby/CKS-E"
	msgbox ,,Help, %txtVar%
	Return
}

JoyPadToggle(){
	Global JoyPadEnabled
	
	Gui, Submit, NoHide
	
	If( JoyPadEnabled ){
		SetJoyPadListening( "On" )
		SetTimer, JoyPadListen, -0
	}Else{
		SetJoyPadListening( "Off" )
	}
}

JoyPadListen(){
	Global IsPaused, JoyPadEnabled, JoyPadAxes
	
	If( JoyPadEnabled ){
		
		JoyPadMoved := False
		
		For JoyPadID, Axes in JoyPadAxes
		{
			For Axis, LastValue in Axes
			{
				GetKeyState, NewValue, %JoyPadID%%Axis%
			
				If( NewValue <> LastValue ){
					JoyPadMoved := True
				}
				Axes[Axis] := NewValue
			}
		}
		
		If( JoyPadMoved ){
			doSend()
		}
		
		SetTimer, , -50
	}else{
		SetTimer, , Off
	}
}

MouseToggle(){
	Global MouseEnabled
	
	Gui, Submit, NoHide
	
	if( MouseEnabled ){
		SetTimer, MouseListen, -0
	}
}

OnMouseInput(){
	Global MouseEnabled
	
	if( MouseEnabled ){
		doSend()
	}
}

$~WheelUp::
	OnMouseInput()
Return

$~WheelDown::
	OnMouseInput()
Return

MouseListen(){
	Global MouseEnabled
	static xPos := -1, yPos := -1
	
	If( MouseEnabled ){
	
		if( xPos = -1 ){
			MouseGetPos, xPos, yPos
		}
	
		MouseGetPos, xPosNew, yPosNew
		
		if (xPos <> xPosNew or yPos <> yPosNew){
			xPos := xPosNew
			yPos := yPosNew
			OnMouseInput()
		}
	
		SetTimer, MouseListen, -50
	}Else{		
		SetTimer, MouseListen, Off
	}
}

RefreshList(){
	Global idList
	Refresh(idList)
	Return
}

ProgramList(){
}

GuiContextMenu(){  
}

IsCheckboxStyle(style)
{
	static types := [ "Button"        ;BS_PUSHBUTTON
                  , "Button"        ;BS_DEFPUSHBUTTON
                  , "Checkbox"      ;BS_CHECKBOX
                  , "Checkbox"      ;BS_AUTOCHECKBOX
                  , "Radio"         ;BS_RADIOBUTTON
                  , "Checkbox"      ;BS_3STATE
                  , "Checkbox"      ;BS_AUTO3STATE
                  , "Groupbox"      ;BS_GROUPBOX
                  , "NotUsed"       ;BS_USERBUTTON
                  , "Radio"         ;BS_AUTORADIOBUTTON
                  , "Button"        ;BS_PUSHBOX
                  , "AppSpecific"   ;BS_OWNERDRAW
                  , "SplitButton"   ;BS_SPLITBUTTON    (vista+)
                  , "SplitButton"   ;BS_DEFSPLITBUTTON (vista+)
                  , "CommandLink"   ;BS_COMMANDLINK    (vista+)
                  , "CommandLink"]  ;BS_DEFCOMMANDLINK (vista+)

	If( types[1+(style & 0xF)] = "Checkbox" )
		Return True
	
	Return False	
}

SaveConfig( ConfigFileName )
{
	Global
	
	ResetIntervals()
	
	HWND := WinExist(windowName)
	WinGet, ctlList, ControlList, ahk_id %HWND%
	Loop, Parse, ctlList,`n 
	{
		isCheckbox := False
		
		If( inStr(a_LoopField,"Button") ){
			ControlGet, styleFlags, Style, , %a_LoopField%
			isCheckBox := IsCheckboxStyle(styleFlags)
		}
		
		If( inStr(a_LoopField,"Edit") or isCheckbox ){
			
			GuiControlGet, varName, Name, %a_LoopField%
							
			GuiControlGet, controlValue, , %varName%
			IniWrite, %controlValue%, %ConfigFileName% , 1, %varName%
			
		}
	}
}

LoadConfig( ConfigFileName )
{
	Global
	HWND := WinExist(windowName)
	WinGet, ctlList, ControlList, ahk_id %HWND%
	Loop, Parse, ctlList,`n 
	{
		isCheckbox := False
		
		If( inStr(a_LoopField,"Button") ){
			ControlGet, styleFlags, Style, , %a_LoopField%
			isCheckBox := IsCheckboxStyle(styleFlags)
		}
		
		If( inStr(a_LoopField,"Edit") or isCheckbox ){
			
			GuiControlGet, varName, Name, %a_LoopField%
							
			IniRead, temp, %ConfigFileName%, 1, %varName%
			StringLeft, cbTest, varName, 2
			; This is horrible but there seems to be no easy way to either detect when a ui element is a combobox
			; or to set the value in the edit box element of the combox box. So, I've had to use "special naming"
			; and a method that adds the value as the new default in the combobox.
			If( cbTest = "CB" ){
				GuiControl,, %varName%, %temp%||
			}Else{
				GuiControl,, %varName%, %temp%
			}
		}
	}
	Gui Submit, NoHide
	
	ApplyIntervals()
	PhsToggle()
	MouseToggle()
	JoyPadToggle()
	KbdToggle()
	ServerModeUpdated()
}

Close(){
	FinaliseAndExit()
}

FinaliseAndExit(){
	Global
	Gui submit, NoHide
	SaveConfig(DefaultConfigFile)
	ExitApp
}

doSend(){
	Global IsPaused, Keys, Seq, SequenceEnabled, RealCBOutputIntervalLow, RealCBOutputIntervalHigh, RandEnabled, NextAllowedOutputTime
	
	If( !IsPaused And A_TickCount >= NextAllowedOutputTime ){
		sendKeys(Keys, Seq++, SequenceEnabled)
		sleepSpecial(RealCBOutputIntervalLow, RealCBOutputIntervalHigh, RandEnabled)
	}
}

Refresh(idList) {
	
    WinGet, id, list,,, Program Manager
    Loop, %id%
    {   
        this_id := id%A_Index%
        if (idList[this_id] = 1)
            continue
        WinGetClass, this_class, ahk_id %this_id%
        WinGetTitle, this_title, ahk_id %this_id%
        if (this_title = "" or this_title = "Start")
            continue
        LV_Add("",this_title,this_class,this_id)
        idList[this_id] := 1
    }

    Loop % LV_GetCount()
    {
        LV_GetText(win_id, A_Index,3)
        IfWinNotExist, ahk_id%win_id%
        {
            LV_Delete(a_index)
            insertList.Remove(win_id)
        }
    }
    LV_ModifyCol(1,"Auto")
    LV_ModifyCol(2,"Auto")
    LV_ModifyCol(3,"Auto")
}

sleepSpecial(CBOutputIntervalLow, CBOutputIntervalHigh, RandEnabled){
	
	Global NextAllowedOutputTime
	
    CBOutputIntervalLow *=1000
    CBOutputIntervalHigh *=1000

    Random, rand, CBOutputIntervalLow, CBOutputIntervalHigh
    NextAllowedOutputTime := A_TickCount + rand
    Return rand
}

sendKeys(Keys, Sequence, SEnabled){
	Global BlockOutput, IsConnected, clientSocket, RealCBKeypressLengthHigh, RealCBKeypressLengthLow, KeypressEmulationEnabled
	
	If( IsConnected ){
		dummyData := 1
		err := AHKsock_ForceSend(clientSocket, &dummyData, 1)
		if( err ){
			GuiControl,, AppStatus, Error sending keys - code = %err%
		}else{
			FormatTime, TimeString, T12, Time
			GuiControl,, AppStatus, Client sent key command at %TimeString%
		}
	}
	
    if (Keys = "")
        Keys := 1
    RowNumber := 0  
	
	StringSplit, KeyArr, Keys, `;

	if (SEnabled) {
		rand := Mod(Sequence, KeyArr0) + 1
	} else {
		Random, rand, 1 , KeyArr0
	}

    keyToSend := keyArr%rand%	
	
	MouseGetPos, , , winOverID
	
	; Send key to all checked applications
    Loop{
        RowNumber := LV_GetNext(RowNumber,"Checked")  
        if not RowNumber  
        break
        
        LV_GetText(win_id, RowNumber,3)

		If( BlockOutput And winOverID = win_id ){
			Continue
		}
		
		IfInString, keyToSend, mclick
		{
			Stringmid, keyToSend, keyToSend, 8
			ControlClick, %keytoSend%, ahk_id%win_id%
		} else{
			If( KeypressEmulationEnabled ){
				ControlSend,, {%keytoSend% down}, ahk_id%win_id%
			}Else{
				ControlSend,, {%keytoSend%}, ahk_id%win_id%
			}
		}
	}
	
	; If keypress emulation is enabled then sleep and then send the key up even to each checked application
	If( KeypressEmulationEnabled ){
		Random, rand, RealCBKeypressLengthLow*1000, RealCBKeypressLengthHigh*1000
		Sleep, rand
		Loop{
			RowNumber := LV_GetNext(RowNumber,"Checked")  
			if not RowNumber  
				break
			ControlSend,, {%keytoSend% up}, ahk_id%win_id%
		}
	}
}

HandleAsServer(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bData = 0, bDataLength = 0) {
    Global

	If (sEvent = "ACCEPTED") {
		GuiControl, , AppStatus, Client connected from %sAddr%...
        OutputDebug, % "A client with IP " sAddr " connected!"
		return
	}
	
	If( sEvent = "RECEIVED"){
		FormatTime, TimeString, T12, Time
		GuiControl, , AppStatus, Received press request. Firing keys at %TimeString%
		doSend()
		return
	}
	
	GuiControl, , AppStatus, Server received event %sEvent%... ;Update status
}

HandleAsClient(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bData = 0, bDataLength = 0) {
	Global
	
	If (sEvent = "CONNECTED") {
		IsConnecting := False
		If (iSocket = -1) {
			GuiControl, , ConnectText, Connect
			GuiControl, , AppStatus, Client connect failed...
			EnableServerOptions()
		}Else{
			GuiControl, , AppStatus, Client connect success... socket = %iSocket%  
			IsConnected := True
		}
		clientSocket := iSocket
		
		return
	}

	If (sEvent = "DISCONNECTED") {
		clientSocket := -1
		IsConnected := False
		EnableServerOptions()
		GuiControl,, AppStatus, Client disconnected...
		return
	}
	If( sEvent = "SEND"){
		return
	}
	GuiControl,, AppStatus, Client received event %sEvent%...     
}

DisableServerOptions(){
	GuiControl, Disable, ServerIP
	GuiControl, Disable, ServerPort
	GuiControl, Disable, ServerModeEnabled
}

EnableServerOptions(){
	GuiControl, Enable, ServerIP
	GuiControl, Enable, ServerPort
	GuiControl, Enable, ServerModeEnabled
}

ConnectButton(){
	Global
	if( ServerModeEnabled ){
		Listen()
	}else{
		Connect()
	}
}

Connect(){
	Global
	
	If( !IsConnected && !IsConnecting ){
		GuiControl, , AppStatus, Trying to connect to %serverIP%... ;Update status
    	If( err := AHKsock_Connect(serverIP, serverPort, "HandleAsClient") ){
			GuiControl, , AppStatus, AHKsock_Connect() failed with return value = %err% and ErrorLevel = %ErrorLevel%
			OutputDebug, % "AHKsock_Connect() failed with return value = " err " and ErrorLevel = " ErrorLevel
			EnableServerOptions()
			GuiControl, , ConnectText, Connect
		}else{
			DisableServerOptions()
			GuiControl, , ConnectText, Disconnect
			IsConnecting := True
		}
	}else{
		AHKsock_Close(clientSocket)
		IsConnected := False
		IsConnecting := False
		clientSocket := -1
		GuiControl, , AppStatus, Disconnected ;Update status
		EnableServerOptions()
	}	
}

Listen(){
	Global
	if( !IsListening ){
		If( err := AHKsock_Listen(serverPort, "HandleAsServer") ){
			OutputDebug, % "AHKsock_Listen() failed with return value = " err " and ErrorLevel = " ErrorLevel
			GuiControl, , AppStatus, Listen failed with return value = %err%... ;Update status
			EnableServerOptions()
			GuiControl, , ConnectText, Listen
		}else{
			DisableServerOptions()
			GuiControl, , ConnectText, StopListening
			GuiControl, , AppStatus, Listening for connection on %serverPort%... ;Update status
			IsListening := True
		}
	}else{
		GuiControl, , AppStatus, Stopped Listening... ;Update status
		EnableServerOptions()
		GuiControl, , ConnectText, Listen
		AHKsock_Listen(serverPort, False)
		AHKsock_Close()
		IsListening := False
	}
}

AHKsockErrors(iError, iSocket) {
	Global
    GuiControl,, AppStatus, Client - Error %iError% with error code = %ErrorLevel%
}

ServerModeUpdated(){
	Global
	Gui Submit, NoHide
	if( ServerModeEnabled ){
		GuiControl ,, ConnectText, &Listen
	}else{
		GuiControl ,, ConnectText, &Connect
	}
}

ServerPortUpdated(){
	Gui Submit, NoHide
}

ServerIPUpdated(){
	Gui Submit, NoHide
}


ResetIntervals(){
	Global

	CBKeypressLengthLow := RealCBKeypressLengthLow
	CBKeypressLengthHigh := RealCBKeypressLengthHigh
	CBOutputIntervalLow := RealCBOutputIntervalLow
	CBOutputIntervalHigh := RealCBOutputIntervalHigh
	GuiControl,,CBOutputIntervalLow,|%OutputIntervalBaseList%|%RealCBOutputIntervalLow%||
	GuiControl,,CBOutputIntervalHigh,|%OutputIntervalBaseList%|%RealCBOutputIntervalHigh%||
	GuiControl,,CBKeypressLengthLow,|%KeypressIntervalBaseList%|%RealCBKeypressLengthLow%||
	GuiControl,,CBKeypressLengthHigh,|%KeypressIntervalBaseList%|%RealCBKeypressLengthHigh%||
}

ApplyIntervals(){
	Global
	Gui submit, NoHide
	
	GuiControlGet, RealCBKeypressLengthLow, ,CBKeypressLengthLow
	GuiControlGet, RealCBKeypressLengthHigh, ,CBKeypressLengthHigh
	GuiControlGet, RealCBOutputIntervalLow, ,CBOutputIntervalLow
	GuiControlGet, RealCBOutputIntervalHigh, ,CBOutputIntervalHigh
	
	ResetIntervals()
	
	GuiControl, Disable, ApplyIntervals 
}


IntervalsUpdated(){
	Global
	Gui submit, NoHide
	
	GuiControlGet, KPIL,,CBKeypressLengthLow
	GuiControlGet, KPIH,,CBKeypressLengthHigh
	GuiControlGet, OIL,,CBOutputIntervalLow
	GuiControlGet, OIH,,CBOutputIntervalHigh
	
	KPILError := False
	KPIHError := False
	OILError := False
	OIHError := False
	
	; It took hours to discover that these checks weren't working because the "Is" keyword doesn't work in if statements
	; with brackets. I'm never touching this half-arsed bumblefuck hack-job of a language again once this is done.
	
	If KPIL Is Not Number
		KPILError := True
	
	If KPIH Is Not Number
		KPIHError := True
	
	
	If( Not(KPILError Or KPIHError) And KPIL > KPIH ){
		KPIHError := True
		KPILError := True
	}
	
	If OIL Is Not Number
		OILError := True
	
	If OIH Is Not Number
		OIHError := True
	

	If( Not(OILError Or OIHError) And OIL > OIH ){
		OILError := True
		OIHError := True
	}
	
	if( OILError ){ 
		GuiControl Show, CBOutputIntervalLowError
	}else{
		GuiControl Hide, CBOutputIntervalLowError
	}
	if( OIHError ){
		GuiControl Show, CBOutputIntervalHighError
	}else{
		GuiControl Hide, CBOutputIntervalHighError
	}
	if( KPILError ){
		GuiControl Show, CBKeypressLengthLowError
	}else{
		GuiControl Hide, CBKeypressLengthLowError
	}
	if( KPIHError ){
		GuiControl Show, CBKeypressLengthHighError
	}else{
		GuiControl Hide, CBKeypressLengthHighError
	}
	
	If( KPIHError Or KPILError Or OILError Or OIHError ){
		GuiControl, Disable, ApplyIntervals 
	}Else{
		GuiControl, Enable, ApplyIntervals 
	}
}