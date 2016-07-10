Describe 'WindowsService Integration Tests'
{
    It 'Test service state' {
        $s = Get-Service 'wuauserv'    
        $s.State -eq 'Stopped' | should be $true
    }
    
    It 'Test service startuptype' {
        $s = Get-CimInstance -ClassName 'win32_service' -Filter 'Name="wuauserv"'
        $s.StartMode -eq 'Manual' | should be $true
    }
}