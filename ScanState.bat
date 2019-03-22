REM ******************************************************************************************
REM This script will take a username and a domain name and run scanstate against that user
REM Version: 1.1 (2019-01-17)
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
REM ******************************************************************************************
REM TODO: Add option for setting USMT path
REM TODO: Add option for setting log path
REM TODO: Add option for setting store path
REM TODO: Add procedure for changing defaults without creating too many options
REM ******************************************************************************************
REM BUG: Does not work when run from network because of path
REM ******************************************************************************************


SETLOCAL

REM ******************************************************************************************
REM Variables
REM ******************************************************************************************
SET USMTDomain=NPNT
SET USMTPath=%~dp0
SET USMTUser=AllUsers
SET USMTArch=amd64
SET USMTRunPath=%~dp0%USMTArch%
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
ECHO Architecture: %USMTArch%
ECHO.
ECHO.
REM ******************************************************************************************


REM Set domain to be used.  Will use NPNT is nothing is set.
SET /P USMTDomain=Domain (Default=NPNT):
IF NOT DEFINED USMTDomain SET USMTDomain=NPNT

REM Sets the path of the USMT as the current folder.
SET USMTPath=%~dp0

REM Sets the user to be selected.
SET /P USMTUser=User (Default=AllUsers):
IF NOT DEFINED USMTUser SET USMTUser=AllUsers

REM Sets the architecture to be used.
SET /P USMTArch=Architecture (Options=amd64 x86 arm64 Default=amd64):
IF NOT DEFINED USMTArch SET USMTArch=amd64

REM Sets the path for the appropriate architecture executable.
SET USMTRunPath=%~dp0%USMTArch%

REM Changes current folder to appropriate architecture executable.
pushd %USMTRunPath%

REM Command parts
REM *******************
SET USMTProc=scanstate
IF "%USMTUser%"=="AllUsers" (
  SET USMTStore="%~dp0..\Data\%ComputerName%"
  SET USMTLog=/l:"%~dp0..\Logs\Scans\%ComputerName%.log"
) ELSE (
  SET USMTStore="%~dp0..\Data\%USMTUser%"
  SET USMTLog=/l:"%~dp0..\Logs\Scans\%USMTUser%.log"
)
SET USMTUserSel=/ue:*\* /ui:%USMTDomain%\%USMTUser%
SET USMTXml=/i:migdocs.xml /i:migapp.xml
SET USMTOvrWr=/o
REM *******************

REM The actual USMT command.
REM If there is no user selection the command is run without the user selection switches
IF "%USMTUser%"=="AllUsers" (
	%USMTProc% %USMTStore% %USMTXml% %USMTOvrWr% %USMTLog%
) ELSE (
	%USMTProc% %USMTStore% %USMTUserSel% %USMTXml% %USMTOvrWr% %USMTLog%
)

REM Reverts currnet folder to initial folder.
popd

pause

