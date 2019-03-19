REM ******************************************************************************************
REM This script will take a username and a domain name and run loadstate against that user
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
REM Added prompting for computer name for the data store folder if all users are being loaded
REM Added scan all users if no user is set
REM ******************************************************************************************
REM TODO: Add option for setting USMT path
REM TODO: Add option for setting log path
REM TODO: Add option for setting store path
REM TODO: Add display of defaults
REM TODO: Add procedure for changing defaults without creating too many options
REM ******************************************************************************************


SETLOCAL

REM Set domain to be used.  Will use NPNT is nothing is set.
SET /P USMTDomain=Domain:
IF NOT DEFINED USMTDomain SET USMTDomain=NPNT

REM Sets the path of the USMT as the current folder.
SET USMTPath=%~dp0

REM Sets the user to be selected.
SET /P USMTUser=User:
IF NOT DEFINED USMTUser SET USMTUser=AllUsers

REM Sets the architecture to be used.
SET /P USMTArch=Architecture:
IF NOT DEFINED USMTArch SET USMTArch=amd64

REM Sets the path for the appropriate architecture executable.
SET USMTRunPath=%~dp0%USMTArch%

REM Changes current folder to appropriate architecture executable.
pushd %USMTRunPath%

REM Command parts
REM *******************
SET USMTProc=loadstate
IF "%USMTUser%"=="AllUsers" (
  SET /P USMTStore=PCName:
) ELSE (
  SET USMTStore=%~d0\Data\%USMTUser%
)
SET USMTUserSel=/ue:*\* /ui:%USMTDomain%\%USMTUser%
SET USMTXml=/i:migdocs.xml /i:migapp.xml
SET USMTOvrWr=/o
SET USMTLog=/l:%~d0\Logs\Scans\%USMTUser%.log
REM *******************

REM The actual USMT command.
REM If there is no user selection the command is run without the user selection switches
IF "%USMTUser%"=="AllUsers" (
	%USMTProc% %USMTStore% %USMTXml% %USMTLog%
) ELSE (
	%USMTProc% %USMTStore% %USMTUserSel% %USMTXml% %USMTLog%
)

REM Reverts currnet folder to initial folder.
popd

pause

