$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-Module "$here\..\ServiceManager.psm1" -Force