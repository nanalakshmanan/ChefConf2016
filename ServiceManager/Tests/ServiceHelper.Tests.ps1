$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

$script:TestService = 'wuauserv'

Describe -Name 'Service Test() Tests' -Tags 'Test' -Fixture {

    BeforeAll {Set-Service $script:TestService -StartupType Manual; Stop-Service $script:TestService}
    AfterAll {Set-Service $script:TestService -StartupType Manual; Stop-Service $script:TestService}
    
    It "Test $($script:TestService) is stopped" {
        $s = New-Service $script:TestService 'Stopped'        

        $s.Test() | should be true
    }
    
    It "Tests $($script:TestService) service as running" {
        $Name = $script:TestService
        Start-Service $Name

        $s = New-Service $Name 'Running'
        $s.Test() | Should be $true
    }

    $TestCases = @(
        @{Name = $script:TestService; State = 'Running'; CompareState = 'Running'; ExpectedResult = $true},
        @{Name = $script:TestService; State = 'Running'; CompareState = 'Stopped'; ExpectedResult = $false},
        @{Name = $script:TestService; State = 'Stopped'; CompareState = 'Running'; ExpectedResult = $false},
        @{Name = $script:TestService; State = 'Stopped'; CompareState = 'Stopped'; ExpectedResult = $true}
    )

    It 'Tests if service <Name> is in state <CompareState> when actual state is <State>' -TestCases $TestCases {
        param($Name, $State, $CompareState, $ExpectedResult)

        if ($State -eq 'Running')
        {        
            Start-Service $Name
        }
        else
        {
            Stop-Service $Name -Force
        }

        $s = New-Service $Name $CompareState
        $s.Test() | Should be $ExpectedResult
    }

    $TestCases = @(
        @{Name = $script:TestService; State = 'Running'; StartupType = 'Disabled'},
        @{Name = $script:TestService; State = 'Stopped'; StartupType = 'Automatic'}
    )

    It 'Tests if State is <State> and StartupType is <StartupType>' -TestCases $TestCases {
        param($Name, $State, $StartupType)

        {$s = New-Service $name $State $StartupType;$s.Test()} | Should Throw
    }

    
    $TestCases = @(
        @{Name = $script:TestService; State = 'Stopped'; ST = 'Disabled';   TestST = 'Disabled'; Expected = $true},
        @{Name = $script:TestService; State = 'Stopped'; ST = 'Automatic';  TestST = 'Disabled'; Expected = $false},
        @{Name = $script:TestService; State = 'Stopped'; ST = 'Manual';     TestST = 'Disabled'; Expected = $false},
        @{Name = $script:TestService; State = 'Running'; ST = 'Manual';     TestST = 'Manual';   Expected = $true},
        @{Name = $script:TestService; State = 'Running'; ST = 'Manual';     TestST = 'Automatic';Expected = $false},
        @{Name = $script:TestService; State = 'Running'; ST = 'Automatic';  TestST = 'Manual';   Expected = $false},
        @{Name = $script:TestService; State = 'Running'; ST = 'Automatic';  TestST = 'Automatic';Expected = $true}
    )

    It 'Tests if Test() returns <Expected> when StartupType for <Name> is set to <ST> and desired is <TestST>' `
    -TestCases $TestCases {
        param($Name, $State, $ST, $TestST, $Expected)

        Set-Service -Name $Name -StartupType $St 

        if ($State -eq 'Running')
        {
            Start-Service $Name
        }
        else
        {
            Stop-Service $Name -Force
        }

        $s = New-Service $name $State $TestST
        
        $s.Test() | Should Be $Expected
    }

    It 'Test for service that is not available' {

        {$s = New-Service 'foobar' 'Stopped';$s.Test()} | Should Throw
    }

    It 'Test if Invoke-DscResource returns results as expected' -Pending {
    
    }

    It 'Test if validate set works' {
        {$s = New-Service $script:TestService 'InvalidState'} | Should Throw
    }
}

Describe 'Service Set() Tests' -Tags 'Set' {
  
    BeforeAll {Set-Service $script:TestService -StartupType Manual; Stop-Service $script:TestService}
    AfterAll {Set-Service $script:TestService -StartupType Manual; Stop-Service $script:TestService}

    $TestCases = @(
      @{Name = $script:TestService; InitialState = 'Running'; FinalState = 'Stopped'},
      @{Name = $script:TestService; InitialState = 'Stopped'; FinalState = 'Running'}
    )

    It 'Tests if service <Name> is in set to state <FinalState> when it is initially <InitialState>' `
        -TestCases $TestCases {
        param($Name, $InitialState, $FinalState)

        if ($InitialState -eq 'Running')
        {
            Start-Service $Name
        }
        else
        {
            Stop-Service $Name -Force
        }

        $s = New-Service $Name $FinalState 
        $s.Set()

        (Get-Service $Name).Status | Should Be $FinalState
    }

    $TestCases = @(
        @{Name = $script:TestService; State = 'Stopped'; StartupType = 'Disabled';  StartMode = 'Disabled'},
        @{Name = $script:TestService; State = 'Running'; StartupType = 'Automatic'; StartMode = 'Auto'}
        @{Name = $script:TestService; State = 'Running'; StartupType = 'Manual';    StartMode = 'Manual'}
    )

    It 'Tests if StartupType for <Name> is set to <StartupType>' -TestCases $TestCases {
        param($Name, $State, $StartupType, $StartMode)

        $s = New-Service $Name $State $StartupType
        $s.Set()

        $Service = Get-CimInstance win32_service -Filter "Name='$Name'"

        $Service.StartMode | Should Be $StartMode
    }
}

Describe 'Service Get() Tests' -Tags 'Get' {
    BeforeAll {Set-Service $script:TestService -StartupType Manual; Stop-Service $script:TestService}
    AfterAll {Set-Service $script:TestService -StartupType Manual; Stop-Service $script:TestService}

    $s = New-Service $script:TestService 'Running'
    
    Start-Service  $script:TestService

    $service = $s.Get()

    $ExpectedResult = @{Name = $script:TestService; State = 'Running'; StartupType = 'Manual'}

    $ExpectedResult.Keys | % {
        It "Get(): Testing if $($_) is $($ExpectedResult[$_])" {
            $service.$_ | Should Be $ExpectedResult[$_]
        }
    }
}

<#


Describe 'nService.GetTargetResource' -Tags 'UnitTests' {
    BeforeAll {Set-Service $script:TestService -StartupType Manual}
    AfterAll  {Set-Service $script:TestService -StartupType Manual}

    $service = Get-TargetResourceHelper -Name $script:TestService -State Running

    $ExpectedResult = @{Name = $script:TestService; State = 'Running'; StartupType = 'Manual'}

    $ExpectedResult.Keys | % {
        It "Get-TargetResourceHelper: Testing if $($_) is $($ExpectedResult[$_])" {
            $service.$_ | Should Be $ExpectedResult[$_]
        }
    }
}

#>