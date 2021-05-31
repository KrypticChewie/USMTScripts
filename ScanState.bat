REM ******************************************************************************************
REM This script will take a username and a domain name and run scanstate against that user
REM Version: 1.5.3 (2021-05-31)
REM Created By: Kris Deen (KrpyticChewie)
REM ******************************************************************************************

ECHO OFF

REM ******************************************************************************************
REM Revisions:
REM Version: 1.0 (2018-12-31)
REM	Initial
REM Version: 1.1 (2019-01-17)
REM	Added architecture selection
REM	(For now you must choose either: amd64 for 64, x86 for 32, armd64 for arm)
REM Version: 1.1.1 (2019-03-19)
REM Added using the computer name for the data store folder if all users are being scanned
REM Added scan all users if no user is set
REM Version: 1.1.1 (2019-03-20)
REM Added log name to be PC name if all users are being processed
REM Added default settings displayed in prompts
REM Version: 1.1.1 (2019-03-21)
REM Added display of defaults at start
REM Added display of defaults at the begining of execution
REM Version: 1.1.1 (2019-03-22)
REM Fixed issue with network paths not working
REM Version: 1.2.0 (2019-03-24)
REM Added architecture detection
REM Version: 1.3.0 (2019-07-08)
REM Added offline scanning
REM Version: 1.3.1 (2020-01-02)
REM Fixed an issue with the Offline Scan option selection not working
REM Version: 1.3.2 (2020-02-12)
REM Added exclusion of logged in user
REM Version: 1.3.3 (2020-02-14)
REM Added architecture automatically set (Itanium will exit the script) and domain detection
REM Version: 1.3.3 (2020-02-18)
REM Made if statements case insensitive, for prompt.  Does not give user selection for offline scan (this is not yet supported)
REM Version: 1.3.4 (2020-02-24)
REM Added date and time to log file name.
REM Version: 1.3.5 (2020-02-24)
REM Added detection for USMT path.
REM Version: 1.3.6 (2020-03-16)
REM Fixed timestamp in log file throwing error when "/" is used as the separator
REM Version: 1.4.0 (2020-07-21)
REM Fixed a mixup between the variables used for the user include and excude switches
REM Added selection of inclusion or exclusion of local users for scanning all users only
REM Version: 1.4.1 (2020-07-29)
REM Error dectection added for no administrative access
REM   Not mitigation at the moment, just a message that shows up after the normal USMT error
REM Error dection added for no errors
REM   A message is displayed
REM Version: 1.5.0 (2020-08-23)
REM Detects OS type and exits if OS type is not Workstation
REM Added detection for XP
REM   If XP is detected the Windows 8 version of USMT will be used
REM   This requires the script to be run from root folder of all the USMT folders
REM   Support has been provided if it is in the previous location but will be removed later
REM Version: 1.5.1 (2021-05-30)
REM Added support for paths with spaces
REM Version: 1.5.2 (2021-05-30)
REM Error dection added for only non-fatal errors
REM   If this is detected a prompt will ask if to retry skipping non-fatal errors
REM   A message is displayed for successful completion when /c is used (different return code)
REM Volume Shadow Copy switch (/vsc) added
REM   This will use volume shadow copy to copy locked files
REM Added parameter support
REM   Whatever is typed as a parameter of the script will be appended to end of the USMT command
REM Version: 1.5.3 (2021-05-31)
REM Added setting of a custom store location
REM		The path supplied must be to another USMT folder with a data folder as the store
REM   The path supplied must have a \ at the end
REM ******************************************************************************************
REM TODO: Add option for setting USMT path
REM TODO: Add option for setting log path
REM TODO: Add procedure for changing defaults without creating too many options
REM ******************************************************************************************
REM BUG: Does not work when run from network because of path (Seems to work on XP)
REM ******************************************************************************************


SETLOCAL

REM ******************************************************************************************
REM Variables
REM ******************************************************************************************
SET USMTDomain=%USERDOMAIN%
SET USMTPath=%~dp0
SET USMTUser=AllUsers
SET USMTArch=%PROCESSOR_ARCHITECTURE%
SET USMTRunPath=%~dp0%USMTArch%
SET USMTOffSwitch=/offlineWinDir:
SET USMTOffPath=:\Windows\
SET USMTTech=%USERNAME%
SET USMTUeSwitch=/ue:
SET USMTUiSwitch=/ui:
SET USMTThisPCName=%COMPUTERNAME%
SET USMTCmd=NoCmd
SET USMTOSType=NotDetected
SET USMTOSVer=NotDetected
SET USMTLegacyPath=NotDetected
SET USMTWin08Folder=USMT80
SET USMTWin10Folder=USMT10
SET USMTVerFolder=NotDetected
SET USMTUseAltUSMTPath=NotSet
SET USMTAltUSMTPath=%USMTPath%
REM ******************************************************************************************


REM ******************************************************************************************
REM Display Defaults
REM ******************************************************************************************
ECHO.
ECHO.
ECHO.
ECHO The default values:
ECHO.
ECHO Domain: %USMTDomain%
ECHO USMT Path: %USMTPath%
ECHO User: All Users
ECHO Architecture (Detected): %USMTArch%
ECHO.
ECHO.
REM ******************************************************************************************


REM Finds and sets the OS type
FOR /F "tokens=2 delims==*" %%A IN ('wmic os get producttype^ /Value ^| findstr "[0-9P]"') DO (
	SET OSTYPE=%%A
)
SET USMTOSType=%OSTYPE%

REM Checks if OS type is workstation and exits if not
IF NOT "%USMTOSType%"=="1" (
	ECHO.USMT does not support server versions of Windows
	pause 
	EXIT /B
)

REM Set domain to be used.  Will use NPNT is nothing is set.
SET /P USMTDomain=Domain ^(Detected=%USERDOMAIN%^):
IF NOT DEFINED USMTDomain SET USMTDomain=%USERDOMAIN%

REM Checks for Itanium architecture and exits if detected as USMT doesn't support it
IF %USMTArch%=="IA64" (
  ECHO.USMT is not compatible with Itanium
  pause
  EXIT /B
)

REM Checks if script path is the old location in sub folder
REM Script should be in root, not in the sub folder
IF NOT EXIST "%USMTPath%%USMTWin10Folder%\" (
	SET USMTLegacyPath=Yes
) ELSE (
	SET USMTLegacyPath=No
)

REM Checks if USMT path is the root or old location in sub folder
REM If in sub folder USMT path is set to folder above
IF "%USMTLegacyPath%"=="Yes" (
	SET USMTPath=%USMTPath%..\
)

REM Finds Windows version
REM From https://ss64.com/nt/ver.html
For /f "tokens=4,5,6 delims=[]. " %%G in ('ver') Do (set _major=%%G& set _minor=%%H& set _build=%%I) 

REM Sets the USMT version for the appropriate architecture executable
REM Exits if version before Windows XP is detcted
IF %_major%==5 (
	SET USMTOSVer=Win 8
) ELSE (
	IF %_major% LSS 5 (
		ECHO.USMT does not support versions before Windows XP
  		pause
  		EXIT /B
	) ELSE (
		SET USMTOSVer=Win 10
  )
)

REM Sets folder name for USMT for detected Windows version
IF "%USMTOSVer%"=="Win 10" (
	SET USMTVerFolder=%USMTWin10Folder%
) ELSE (
	IF "%USMTOSVer%"=="Win 8" (
		SET USMTVerFolder=%USMTWin08Folder%
	)
)

REM Sets the path for the appropriate architecture executable.
IF "%USMTLegacyPath%"=="No" (
	SET USMTRunPath=%~dp0%USMTVerFolder%\%USMTArch%
) ELSE (
	ECHO.Script seems to be running from old location
	ECHO.Script should be in the root folder of all USMT folders, as at version 1.4.0
	ECHO.Script should be in the root folder of all USMT folders, as at version 1.5.0
	ECHO.Script will attempt running using legacy paths
	SET USMTRunPath=%~dp0%USMTArch%
)

REM Check if path exists and exits script if not.
IF NOT EXIST "%USMTRunPath%\" (
  ECHO.USMT executable for %USMTOSVer% version and %USMTArch% architecture not found.
  pause
  EXIT /B
)

REM Sets use scan to offline.
SET /P USMTUseOff=Offline Scan? (Options=Yes No Default=No):
IF NOT DEFINED USMTUseOff SET USMTUseOff=No

REM Sets offline Windows folder path
IF /I "%USMTUseOff%"=="Yes" (
  SET /P USMTOffDrive=Offline Windows Drive ^(E.g. X Default=C^):
  IF NOT DEFINED USMTOffDrive SET USMTOffDrive=C
) ELSE (
  REM Sets the user to be selected.
  SET /P USMTUser=User ^(Default=AllUsers^):
  IF NOT DEFINED USMTUser SET USMTUser=AllUsers
)

REM Sets exclude scanning of logged in user.
SET /P USMTUserEx=Exclude logged in user? (Options=Yes No Default=Yes):
IF NOT DEFINED USMTUserEx SET USMTUserEx=Yes

REM Sets exclude scanning of local users.
SET /P USMTLocalsEx=Exclude local users? (Options=Yes No Default=Yes):
IF NOT DEFINED USMTLocalsEx SET USMTLocalsEx=Yes

REM Sets using custom store location.
SET /P USMTUseAltUSMTPath=Sets custom store location? (Options=Yes No Default=Yes):
IF NOT DEFINED USMTUseAltUSMTPath SET USMTUseAltUSMTPath=No

REM Changes current folder to appropriate architecture executable.
pushd %USMTRunPath%

REM Sets the date and time aspect of the log file and changes / to -
SET LogStamp=%DATE% %TIME%
SET LogStamp=%LogStamp:/=-%
SET LogStamp=%LogStamp::=-%


REM Command parts
REM *******************
SET USMTProc=scanstate

REM Checks if custom store path was selected and prompts for path.
REM If no path is given the current USMT path is used.
IF /I "%USMTUseAltUSMTPath%"=="Yes" (
  SET /P USMTStorePath=Set custom store path to data folder ^(Include ending \^):
)
IF NOT DEFINED USMTStorePath SET USMTStorePath=%USMTPath%
IF NOT EXIST "%USMTStorePath%" (
	ECHO Custom path not valid or accessible
	ECHO Using current path
	SET USMTStorePath=%USMTPath%
)

IF "%USMTUser%"=="AllUsers" (
  SET USMTStore="%USMTStorePath%Data\%ComputerName%"
  SET USMTLog=/l:"%USMTPath%Logs\Scans\%ComputerName% - %LogStamp%.log"
) ELSE (
  SET USMTStore="%USMTStorePath%Data\%USMTUser%"
  SET USMTLog=/l:"%USMTPath%Logs\Scans\%USMTUser% - %LogStamp%.log"
)
SET USMTUserSel=/ue:*\* /ui:%USMTDomain%\%USMTUser%
IF /I "%USMTUserEx%"=="Yes" (
  SET USMTUserCmd=%USMTUeSwitch%*\%USMTTech%
) ELSE (
  SET USMTUserCmd=%USMTUiSwitch%*\%USMTTech%
)
IF /I "%USMTLocalsEx%"=="Yes" (
  SET USMTLocalsExCmd=%USMTUeSwitch%%USMTThisPCName%\*
) ELSE (
  SET USMTLocalsExCmd=%USMTUiSwitch%%USMTThisPCName%\*
)
SET USMTUserSel=/ue:*\* /ui:%USMTDomain%\%USMTUser%
SET USMTXml=/i:migdocs.xml /i:migapp.xml
SET USMTOvrWr=/o
IF /I "%USMTUseOff%"=="Yes" (
  SET USMTOffCmd=%USMTOffSwitch%%USMTOffDrive%%USMTOffPath%
)
REM *******************

REM The actual USMT command.
REM If there is no user selection the command is run without the user selection switches
IF "%USMTUser%"=="AllUsers" (
	SET USMTCmd=%USMTProc% %USMTStore% %USMTUserCmd% %USMTLocalsExCmd% %USMTXml% %USMTOvrWr% %USMTLog% %USMTOffCmd% %USMTVscSwitch% %1
) ELSE (
  SET USMTCmd=%USMTProc% %USMTStore% %USMTUserSel% %USMTXml% %USMTOvrWr% %USMTLog% %USMTOffCmd% %USMTVscSwitch% %1
  )
)

%USMTCmd%
REM *******************

REM *******************
REM Error handling for Scanstate executable
REM *******************

REM No errors were detected
IF "%ErrorLevel%"=="0" (
  ECHO The operation was completed with no errors reported
)

REM Non fatal errors were detected and skipped as /c was selected
IF "%ErrorLevel%"=="3" (
  ECHO The operation was completed with only non-fatal errors reported
)

REM Detected no admin rights
IF "%ErrorLevel%"=="34" (
  ECHO You need to start the script with administrative rights
)

REM Detected stop due to non-fatal errors
IF "%ErrorLevel%"=="61" (
  SET /P USMTSkipNonFatal=Try again skipping errors? ^(Options=Yes No Default=No^):
  IF NOT DEFINED USMTSkipNonFatal SET USMTSkipNonFatal=No
)
IF /I "%USMTSkipNonFatal%"=="Yes" (
  %USMTCmd% /c
)
REM *******************

REM Reverts currnet folder to initial folder.
popd

pause