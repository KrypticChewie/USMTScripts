REM ******************************************************************************************
REM This script will take a username and a domain name and run scanstate against that user
REM Version: 1.0 (2018-12-31)
REM Created By: Kris Deen (KrpyticChewie)
REM ******************************************************************************************

ECHO OFF

REM ******************************************************************************************
REM Revisions:
REM Version: 1.0 (2018-12-31)
REM	Initial
REM ******************************************************************************************


SETLOCAL
SET /P USMTDomain=Domain:
IF NOT DEFINED USMTDomain SET USMTDomain=NPNT
SET USMTPath=%~dp0
SET /P USMTUser=User:

pushd %~dp0\amd64

scanstate %~d0\Data\%USMTUser% /ue:*\* /ui:%USMTDomain%\%USMTUser% /i:migdocs.xml /i:migapp.xml /o /l:%~d0\Logs\Scans\%USMTUser%.log

popd

pause

