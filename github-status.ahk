; github-status.ahk
; A simple tray-icon app to check GitHub's status.

#Include <json>
#NoEnv
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
showTrayTip(getStatus(), getLastMessage())
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
getStatusURL()
{
	static statusURL

	if (statusURL = "")
	{
		UrlDownloadToFile, *0 https://status.github.com/api.json, %A_Temp%\github_api.json
		FileRead, api, %A_Temp%\github_api.json
		statusURL := json(api, "status_url")
	}

	return statusURL	
}

getLastMessageURL()
{
	static messageURL

	if (messageURL = "")
	{
		UrlDownloadToFile, *0 https://status.github.com/api.json, %A_Temp%\github_api.json
		FileRead, api, %A_Temp%\github_api.json
		messageURL := json(api, "last_message_url")
	}

	return messageURL
}

getStatus()
{
	statusURL := getStatusURL()
	UrlDownloadToFile, %statusURL%, %A_Temp%\github_status.json
	FileRead, status, %A_Temp%\github_status.json
	return json(status, "status")
}

getLastUpdated()
{
	statusURL := getStatusURL()
	UrlDownloadToFile, *0 %statusURL%, %A_Temp%\github_status.json
	FileRead, status, %A_Temp%\github_status.json
	return json(status, "last_updated")
}

getLastMessage()
{
	lastMessageURL := getLastMessageURL()
	UrlDownloadToFile, %lastMessageURL%, %A_Temp%\github_last_message.json
	FileRead, lastMessage, %A_Temp%\github_last_message.json
	return json(lastMessage, "body")
}

setTrayIcon(status)
{
	if (status = "major")
		icon := A_Temp . "\github_status_img\major.ico"
	else if (status = "minor")
		icon := A_Temp . "\github_status_img\minor.ico"
	else if (status = "good")
		icon := A_Temp . "\github_status_img\good.ico"
	else
		icon := A_Temp . "\github_status_img\unknown.ico"

	Menu, Tray, Icon, %icon%
}

setToolTip(status, lastUpdated)
{
	Menu, Tray, Tip, Status: %status%`nLast updated %lastUpdated%
}

showTrayTip(status, message)
{
	if (status = "major")
		icon := 3
	else if (status = "minor")
		icon := 2
	else if (status = "good")
		icon := 1
	; else use the default (blank)

	TrayTip, GitHub Status: %status%, %message%,, %icon%
}

updateAll()
{
	static lastMessage

	status := getStatus()
	setTrayIcon(status)
	setToolTip(status, getLastUpdated())

	newMessage := getLastMessage()
	if (lastMessage != newMessage)
	{
		showTrayTip(status, newMessage)
		lastMessage := newMessage
	}
}
