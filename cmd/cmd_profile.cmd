; cmd_profile.cmd — Dotfiles Citadel  ·  Command Prompt (cmd.exe) profile
; Managed by: https://github.com/geekedsilicon/dotfiles
;
; Sourced automatically via the HKCU AutoRun registry key (set by setup.ps1).
; Customise prompt, add aliases (via DOSKEY), and set env vars here.
;
; Author:  geekedsilicon
; Version: 1.0.0

@echo off

:: ---------------------------------------------------------------------------
:: Custom prompt  (PowerShell-style: PS C:\path> )
:: ---------------------------------------------------------------------------
PROMPT $E[36m$P$E[0m$G$S

:: ---------------------------------------------------------------------------
:: DOSKEY aliases
:: ---------------------------------------------------------------------------
DOSKEY ls    = dir /B $*
DOSKEY ll    = dir /A $*
DOSKEY grep  = findstr $*
DOSKEY g     = git $*
DOSKEY cls   = cls
DOSKEY ..    = cd ..
DOSKEY ...   = cd ..\..

:: ---------------------------------------------------------------------------
:: Workspace shortcut
:: ---------------------------------------------------------------------------
SET WORKSPACE=%USERPROFILE%\workspace

:: ---------------------------------------------------------------------------
:: Done
:: ---------------------------------------------------------------------------
:: (No echo — keeps shell startup silent)
