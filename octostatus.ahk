; A simple tray-icon app to check GitHub's status.

#Include <json>
#NoEnv
#SingleInstance,Force
SendMode Input
SetWorkingDir %A_ScriptDir%
OnExit, ExitRoutine

; Config
; How long to wait before each status check, in ms:
waitTime := 300000  ; 5 minutes

; Tray menu
Menu, Tray, NoStandard
Menu, Tray, Add, &Show status, ShowStatus
Menu, Tray, Add, https://status.&github.com/, GitHubStatus
Menu, Tray, Add, &Exit, ExitRoutine
Menu, Tray, Default, &Show status

; Image files
FileCreateDir, %A_Temp%\github_status_img
FileInstall, img\major.ico, %A_Temp%\github_status_img\major.ico
FileInstall, img\minor.ico, %A_Temp%\github_status_img\minor.ico
FileInstall, img\good.ico, %A_Temp%\github_status_img\good.ico
FileInstall, img\unknown.ico, %A_Temp%\github_status_img\unknown.ico

; Main program loop
Loop
{
	updateAll()
	Sleep, %waitTime%
}
Return

; On-demand tray tip
ShowStatus:
{
	jsonResponse := getStatusJson()
	showTrayTip(getStatus(jsonResponse), getLastMessage(jsonResponse))
}
Return

; Go to status.github.com
GitHubStatus:
Run, https://status.github.com/
Return

; Clean up on exit
ExitRoutine:
FileRemoveDir, %A_Temp%\github_status_img, 1
ExitApp
Return

; Functions
URLDownloadToVar(url){
	hObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
	hObject.Open("GET",url)
	hObject.Send()
	return hObject.ResponseText
}

getStatusJson(){
	fullJson := URLDownloadToVar("https://kctbh9vrtdwd.statuspage.io/api/v2/status.json")
	return fullJson
}

getStatus(jsonResponse){
  s := json(jsonResponse, "status")
	return json(s, "indicator")
}

getLastUpdated(jsonResponse){
  page := json(jsonResponse, "page")
	return json(page, "updated_at")
}

getLastMessage(jsonResponse){
  s := json(jsonResponse, "status")
	return json(s, "description")
}

setTrayIcon(status){
	if (status = "critical")
		icon := A_Temp . "\github_status_img\critical.ico"
	else if (status = "major")
		icon := A_Temp . "\github_status_img\major.ico"
	else if (status = "minor")
		icon := A_Temp . "\github_status_img\minor.ico"
	else if (status = "none")
		icon := A_Temp . "\github_status_img\good.ico"
	else
		icon := A_Temp . "\github_status_img\unknown.ico"

	Menu, Tray, Icon, %icon%
}

setToolTip(status, lastUpdated){
	Menu, Tray, Tip, Status: %status%`nLast updated %lastUpdated%
}

showTrayTip(status, message){
	if (status = "major")
		icon := 3
	else if (status = "minor")
		icon := 2
	else if (status = "good")
		icon := 1
	; else use the default (blank)

	TrayTip, GitHub Status, %message%,, %icon%
}

updateAll(){
  ; do not report All Systems Operational first time after launched
	static lastMessage = "All Systems Operational"
	
	jsonResponse := getStatusJson()

	status := getStatus(jsonResponse)
	setTrayIcon(status)
	setToolTip(status, getLastUpdated(jsonResponse))

	newMessage := getLastMessage(jsonResponse)
	if (lastMessage != newMessage)
	{
		showTrayTip(status, newMessage)
		lastMessage := newMessage
	}
}
