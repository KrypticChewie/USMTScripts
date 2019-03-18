

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
REM ******************************************************************************************
REM TODO: Add option for load all users
REM ******************************************************************************************


SETLOCAL
SET /P USMTDomain=Domain:
IF NOT DEFINED USMTDomain SET USMTDomain=NPNT
SET USMTPath=%~dp0
SET /P USMTUser=User:

SET /P USMTArch=Architecture:
IF NOT DEFINED USMTArch SET USMTArch=amd64

SET USMTRunPath=%~dp0%USMTArch%

pushd %USMTRunPath%

loadstate %~d0\Data\%USMTUser% /ue:*\* /ui:%USMTDomain%\%USMTUser% /i:migdocs.xml /i:migapp.xml /l:%~d0\Logs\Loads\%USMTUser%.log

popd

pause

