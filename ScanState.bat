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
REM ******************************************************************************************
REM TODO: Add option for scan all users
REM TODO: Add option for setting USMT path
REM ******************************************************************************************


SETLOCAL

REM Set domain to be used.  Will use NPNT is nothing is set.
SET /P USMTDomain=Domain:
IF NOT DEFINED USMTDomain SET USMTDomain=NPNT

REM Sets the path of the USMT as the current folder
SET USMTPath=%~dp0

REM Sets the user to be selected.
SET /P USMTUser=User:

REM Sets the architecture to be used.
SET /P USMTArch=Architecture:
IF NOT DEFINED USMTArch SET USMTArch=amd64

REM Sets the path for the appropriate architecture executable.
SET USMTRunPath=%~dp0%USMTArch%

REM Changes current folder to appropriate architecture executable.
pushd %USMTRunPath%

REM The actual USMT command.
scanstate %~d0\Data\%USMTUser% /ue:*\* /ui:%USMTDomain%\%USMTUser% /i:migdocs.xml /i:migapp.xml /o /l:%~d0\Logs\Scans\%USMTUser%.log

REM Reverts currnet folder to initial folder.
popd

pause

