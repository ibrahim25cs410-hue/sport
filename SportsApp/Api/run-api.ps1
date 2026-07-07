#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
& (Join-Path $root "scripts\run-api.ps1")
