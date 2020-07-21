REM ******************************************************************************************
REM This script will take a username and a domain name and run scanstate against that user
REM Version: 1.3.5 (2020-02-24)
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
REM ******************************************************************************************
REM TODO: Add option for setting USMT path
REM TODO: Add option for setting log path
REM TODO: Add option for setting store path
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


REM Set domain to be used.  Will use NPNT is nothing is set.
SET /P USMTDomain=Domain ^(Detected=%USERDOMAIN%^):
IF NOT DEFINED USMTDomain SET USMTDomain=%USERDOMAIN%

REM Sets the path of the USMT as the current folder.
SET USMTPath=%~dp0

REM Sets the user to be selected.
REM SET /P USMTUser=User (Default=AllUsers):
REM IF NOT DEFINED USMTUser SET USMTUser=AllUsers

IF %USMTArch%=="IA64" (
  ECHO. USMT is not compatible with Itanium
  pause
  EXIT /B
)

REM Sets the path for the appropriate architecture executable.
SET USMTRunPath=%~dp0%USMTArch%

REM Check if path exists and exits script if not.
IF NOT EXIST %USMTRunPath%\Nul (
  ECHO.USMT executable for %USMTArch% architecture not found.
  pause
  EXIT /B
)

REM Changes current folder to appropriate architecture executable.
pushd %USMTRunPath%

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

REM Sets the date and time aspect of the log file and changes / to -
SET LogStamp=%DATE% %TIME%
SET LogStamp=%LogStamp:/=-%
SET LogStamp=%LogStamp::=-%


REM Command parts
REM *******************
SET USMTProc=scanstate
IF "%USMTUser%"=="AllUsers" (
  SET USMTStore="%~dp0..\Data\%ComputerName%"
  SET USMTLog=/l:"%~dp0..\Logs\Scans\%ComputerName% - %LogStamp%.log"
) ELSE (
  SET USMTStore="%~dp0..\Data\%USMTUser%"
  SET USMTLog=/l:"%~dp0..\Logs\Scans\%USMTUser% - %LogStamp%.log"
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
	%USMTProc% %USMTStore% %USMTUserCmd% %USMTLocalsExCmd% %USMTXml% %USMTOvrWr% %USMTLog% %USMTOffCmd%
) ELSE (
  %USMTProc% %USMTStore% %USMTUserSel% %USMTXml% %USMTOvrWr% %USMTLog% %USMTOffCmd%
  )
)

REM Reverts currnet folder to initial folder.
popd

pause