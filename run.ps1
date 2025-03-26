#!/usr/bin/env pwsh

# Exit immediately if any commands fail
$ErrorActionPreference = "Stop"

# Get the directory where the script is located
$ScriptDir = $PSScriptRoot

# Compile the program
Push-Location $ScriptDir
try {
    zig build
}
finally {
    Pop-Location
}

& "$ScriptDir\zig-out\bin\main.exe" $args
