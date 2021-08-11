#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Grandstream HTX config tool
; By Sean Leckie - Licensed under MIT
; This tool is a (somewhat hacky) way to automate configuration of customer ATAs
; It uses the plink.exe client from PuTTY, which should be placed in the same dir as this script.
; If plink.exe is not found, it attempts to install the native Windows SSH client

; variables: change these to whatever you need for your ATA config

atausername := "admin"
primaryserver := ""
failoverserver := ""
timeout := 4
sshclient := plink

; path to plink.exe
CurrentFile = plink.exe
FileFullPath:=A_Scriptdir . "\" . CurrentFile

if !FileExist(FileFullPath)
{
	MsgBox, Looks like plink isn't in the current directory. We're falling back on Windows OpenSSH, so you'll need to grant administrator rights. If that doesn't work, go grab a copy of plink.exe. This message box will appear twice.
	sshclient := ssh
	
	; import RunAsTask
	/*     
	RunAsTask() - Auto-elevates script without UAC prompt |  http://ahkscript.org/boards/viewtopic.php?t=4334        
	_________________________________________________________________________________________________________
	*/
	 
	RunAsTask() {                         ;  By SKAN,  http://goo.gl/yG6A1F,  CD:19/Aug/2014 | MD:24/Apr/2020

	  Local CmdLine, TaskName, TaskExists, XML, TaskSchd, TaskRoot, RunAsTask
	  Local TASK_CREATE := 0x2,  TASK_LOGON_INTERACTIVE_TOKEN := 3 

	  Try TaskSchd  := ComObjCreate( "Schedule.Service" ),    TaskSchd.Connect()
		, TaskRoot  := TaskSchd.GetFolder( "\" )
	  Catch
		  Return "", ErrorLevel := 1    
	  
	  CmdLine       := ( A_IsCompiled ? "" : """"  A_AhkPath """" )  A_Space  ( """" A_ScriptFullpath """"  )
	  TaskName      := "[RunAsTask] " A_ScriptName " @" SubStr( "000000000"  DllCall( "NTDLL\RtlComputeCrc32"
					   , "Int",0, "WStr",CmdLine, "UInt",StrLen( CmdLine ) * 2, "UInt" ), -9 )

	  Try RunAsTask := TaskRoot.GetTask( TaskName )
	  TaskExists    := ! A_LastError 


	  If ( not A_IsAdmin and TaskExists )      { 

		RunAsTask.Run( "" )
		ExitApp

	  }

	  If ( not A_IsAdmin and not TaskExists )  { 

		Run *RunAs %CmdLine%, %A_ScriptDir%, UseErrorLevel
		ExitApp

	  }

	  If ( A_IsAdmin and not TaskExists )      {  

		XML := "
		( LTrim Join
		  <?xml version=""1.0"" ?><Task xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task""><Regi
		  strationInfo /><Triggers /><Principals><Principal id=""Author""><LogonType>InteractiveToken</LogonT
		  ype><RunLevel>HighestAvailable</RunLevel></Principal></Principals><Settings><MultipleInstancesPolic
		  y>Parallel</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><
		  StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>false</AllowHardTerminate>
		  <StartWhenAvailable>false</StartWhenAvailable><RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAva
		  ilable><IdleSettings><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleS
		  ettings><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>false</Hidden><
		  RunOnlyIfIdle>false</RunOnlyIfIdle><DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteApp
		  Session><UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine><WakeToRun>false</WakeToRun><
		  ExecutionTimeLimit>PT0S</ExecutionTimeLimit></Settings><Actions Context=""Author""><Exec>
		  <Command>""" ( A_IsCompiled ? A_ScriptFullpath : A_AhkPath ) """</Command>
		  <Arguments>" ( !A_IsCompiled ? """" A_ScriptFullpath  """" : "" )   "</Arguments>
		  <WorkingDirectory>" A_ScriptDir "</WorkingDirectory></Exec></Actions></Task>
		)"    

		TaskRoot.RegisterTask( TaskName, XML, TASK_CREATE, "", "", TASK_LOGON_INTERACTIVE_TOKEN )

	  }         

	Return TaskName, ErrorLevel := 0
	} ; 
	RunAsTask()
	Run powershell.exe
	Sleep, 2000
	Send, echo "Installing SSH. Please press the enter key twice when complete."{enter}
	Send, Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0{enter}
	Input, SingleKey, L1, {enter}
	Send, {enter}
	Send, exit
	Input, SingleKey, L1 V, {enter}
}

Run cmd.exe
Sleep, 2000	
Send, prompt ${enter}
Send, cls{enter}
Send, ==================================^C
Send, SLE's Grandstream FTP Setup Script^C
Send, ==================================^C^C
Send, We're now going to get some info from you. ^C
Send, Current ATA Password? Please enter, then the press enter key:^C >
Input, currentpassword, V, {Enter}
Send, cls{enter}IP address of ATA? Please enter, then press the enter key:^C >
Input, ipaddress, V, {Enter}
Send, cls{enter}Customer's phone number - please include leading 1, ie 15191234567. Then press the enter key. ^C >
Input, phonenumber, V, {Enter}
Send, cls{enter}SIP password, as seen in account details? Please enter, then press the enter key: ^C >
Input, sippass, V, {Enter}
if (!primaryserver)
{
	Send, cls{enter}What is the primary SIP server address? Please enter, then press the enter key: ^C >
	Input, primaryserver, V, {Enter}
}
if (!failoverserver)
{
	Send, cls{enter}Do you wish to set a failover server (y/n)?: >
	Input, bool, L1
	if("y" = bool)
	{
		Send, ^Ccls{enter}What is the failover SIP server address? Please enter, then press the enter key: ^C >
		Input, failoverserver, V, {Enter}
	}
}
Send, ^Ccls{enter}Are we resetting the ATA first (y/n)?: >
Input, bool, L1

if ("y" = bool)
{
	Send, ^Ccls{enter}
	Send, =====================================================================^C
	Send, We will now reset the ATA. Do NOT touch anything during this process.^C
	Send, =====================================================================^C
	Sleep, 5000
	Send, cls{enter}
	Send, ssh %atausername%@%ipaddress%{enter}
	sleep, 5000
	Send, %currentpassword%{enter}
	sleep, 500
	Send, reset 0{enter}
	sleep, 500
	send, y{enter}
	sleep, 90000
	send, cls{enter}
	Send, ====================================^C
	Send, ATA should now be reset. Continuing.^C
	Send, ====================================^C
} else if ("n" = bool)
{
	Send, ^Cnot resetting
} else {
	Send, ^Cinvalid input, not resetting.
}
Send, ^CEnter the account number of the customer. This will become the ATA password. Please enter, then press the enter key: ^C >
Input, accountnumber, V, {Enter}
if (failoverserver)
{
	Send, cls{enter}Last question. Do we need to use the alternate server? Unless you know to, say no.^C
	Send, (y/n)?: >
	Input, bool, L1

	if("y" = bool)
	{
		temp := primaryserver
		primaryserver := failoverserver
		failoverserver := temp
		Send, ^CSwapped primary and failover servers. Primary server is now %primaryserver%^C
		Send, Please note that at this time this script does NOT also turn off Random SIP/RTP.^C
		sleep, 1000
	} else {
		Send, Sticking with the default, %primaryserver%^C
		sleep, 1000
	}
}
Send, cls{enter}
Send, =======================================================^C
Send, We will now access the ATA and apply the settings.^C
Send, Do NOT touch anything unless you are prompted with a >
Send, ^C
Send, =======================================================^C^C
sleep, 5000
send, cls{enter}

Send, ssh admin@%ipaddress%{enter}
sleep, 5000
Send, admin{enter}
sleep, 500
Send, status{enter}
sleep, 100
Send, Check firmware to make sure it is up to date. If it's not, it's best to use the web interface to update it. Press enter to continue. >
Input, InputKey, V, {enter}
Send, config{enter}
sleep, 100
; end user password
Send, set 196 %accountnumber%{enter}
sleep, 100
; telnet
Send, set 276 0{enter}
sleep, 100
; time zone
Send, set 64 EST5EDT{enter}
sleep, 100
; Admin password
Send, set 2 %accountnumber%{enter}
sleep, 100
; Lock keypad update
Send, set 88 0{enter}
sleep, 100
; Disable direct IP call
Send, set 277 1{enter}
sleep, 100
; primary server
Send, set 47 %primaryserver%{enter}
sleep, 100
; failover server
Send, set 967 %failoverserver%{enter}
sleep, 100
; NAT traversal keep-alive
Send, set 52 2{enter}
sleep, 100
; User ID
Send, set 35 %phonenumber%{enter}
sleep, 100
; Authenticate ID
Send, set 36 %phonenumber%{enter}
sleep, 100
; Authenticate password
Send, set 34 %sippass%{enter}
sleep, 100
; Outgoing call without registration
Send, set 109 0{enter}
sleep, 100
; Random SIP port
Send, set 20501 1{enter}
sleep, 100
; Random RTP port
Send, set 20505 1{enter}
sleep, 100
; support SIP instance ID
Send, set 288 1{enter}
sleep, 100
; SIP proxy only
Send, set 243 1{enter}
sleep, 100
;P-Preferred-Identity Header
Send, set 2339 0{enter}
sleep, 100
;DTMF
Send, set 850 101{enter}
sleep, 100
Send, set 851 100{enter}
sleep, 100
Send, set 852 102{enter}
sleep, 100
; Call features
Send, set 191 0{enter}
sleep, 100
; No key timeout
Send, set 85 %timeout%{enter}
sleep, 100
; Early dial
Send, set 29 0{enter}
sleep, 100
; Vocoder - this only sets 1-7, I believe an eigth has been added, but it shouldn't be an issue
Send, set 57 0{enter}
sleep, 100
Send, set 58 18{enter}
sleep, 100
Send, set 59 0{enter}
sleep, 100
Send, set 60 0{enter}
sleep, 100
Send, set 61 0{enter}
sleep, 100
Send, set 62 0{enter}
sleep, 100
Send, set 63 0{enter}
sleep, 100
; apply
Send, commit{enter}
sleep, 100
; apply
Send, exit{enter}
sleep, 100
Send, exit{enter}
sleep, 100
Send, =======================================================================^C
Send, ATA is now configured and will reboot, should take less than 2 minutes.^C
Send, Once all three lights on ATA blue, you're good to go. Hope this helps.^C
Send, =======================================================================^C
Send, ssh %atausername%@%ipaddress%{enter}
sleep, 5000
Send, %currentpassword%{enter}
sleep, 500
Send, reboot{enter}
sleep, 90000
Send, ^C
sleep, 500
Send, =======================================================================^C
Send, Your ATA should now be rebooted. You may close this window.^C
Send, =======================================================================^C
; exit
; TODO - Why doesn't this close the script???
Exit
