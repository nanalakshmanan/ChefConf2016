Describe 'WindowsService Integration Tests' {

    $Name = 'wuauserv'
    It 'Test service state' {
        $s = Get-Service $Name   
        $s.Status -eq 'Stopped' | should be $true
    }
    
    It 'Test service startuptype' {
        $s = Get-CimInstance -ClassName 'win32_service' -Filter "Name='$Name'"
        $s.StartMode -eq 'Manual' | should be $true
    }
}