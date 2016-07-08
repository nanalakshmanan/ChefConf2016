[DSCResource()]
class Service
{

  #region Properties

  [DscProperty(Key)]
  [string]$Name

  [DscProperty(NotConfigurable)]
  [string] $DisplayName

  [ValidateSet('Running', 'Stopped')]
  [DscProperty(Mandatory)]
  [string] $State

  [ValidateSet('Automatic', 'Manual', 'Disabled')]
  [DscProperty()]
  [string] $StartupType 

  #endregion Properties

  #region DSC Methods
  [Service] Get()
  {
      $Service = $this.GetService()
      $ServiceWmiObject = $this.GetCimService()

      return @{
		            StartupType  = [System.String]($this.NormalizeStartupType($ServiceWmiObject.StartMode))
		            Name         = [System.String]$service.Name
		            DisplayName  = [System.String]$service.DisplayName
		            State        = [System.String]$service.Status
	            }
  }

  [bool] Test()
  {
      $this.ValidateStartupType()

      $service = $this.GetService()

      if ($service.Status -ne $this.State)
      {
          Write-Verbose "Service $($this.Name) is $($Service.Status). Desired state is $($this.State)"
          return $false
      }

      $ServiceWmiObject = $this.GetCimService()

      if (-not [string]::IsNullOrEmpty($($this.StartupType)))
      {
          if (-not ($this.StartupType -eq 'Automatic' -and $ServiceWmiObject.StartMode -eq 'Auto') -and 
              -not ($this.StartupType -eq 'Disabled'  -and $ServiceWmiObject.StartMode -eq 'Disabled') -and
              -not ($this.StartupType -eq 'Manual'    -and $ServiceWmiObject.StartMode -eq 'Manual'))      
          {
              Write-Verbose "Service $($this.Name) is $($ServiceWmiObject.StartMode). Desired startup type is $($this.StartupType)"
              return $false
          }
      }

      return $true
  }

  [void] Set()
  {
      $this.ValidateStartupType()

      $service = $this.GetService()

      if (-not [string]::IsNullOrEmpty($this.StartupType))
      {
          Write-Verbose "Setting startup type of service $($this.Name) to $($this.StartupType)"
          Set-Service -Name $($this.Name) -StartupType $this.StartupType
      }

      if ($this.State -eq 'Running')
      {
          Write-Verbose "Starting service $($this.Name)"
          Start-Service $this.Name
      }
      else
      {
          Write-Verbose "Stopping service $($this.Name)"
          Stop-Service $this.Name -Force
      }
  }

  #endregion DSC Methods

  #region Helper Methods

    <#
    .Synopsis
    Tests if startup type specified is valid, given the specified state
    #>
    hidden [void] ValidateStartupType()
    {
      if([string]::IsNullOrEmpty($this.StartupType)) {return}

      if($this.State -eq 'Stopped')
      {
          if($this.StartupType -eq 'Automatic')
          {
              # State = Stopped conflicts with Automatic or Delayed
              throw "Cannot stop service $($this.Name) and set it to start automatically"
          }
      }
      else
      {
          if($this.StartupType -eq 'Disabled')
          {
              # State = Running conflicts with Disabled
              throw "Cannot start service $($this.Name) and disable it"
          }
      }
    }    

    <#
    .Synopsis
    Gets a service corresponding to a name, throwing an error if not found
    #>
    hidden [System.ServiceProcess.ServiceController] GetService()
    {
        $svc=Get-Service $this.Name -ErrorAction Ignore

        if($svc -eq $null)
        {
            throw "Service with name $($this.Name) not found"
        }

        return $svc
    }

    <#
    .Synopsis
    Gets a Win32_Service object corresponding to the name
    #>
    hidden [Microsoft.Management.Infrastructure.CimInstance] GetCimService()
    {
        try
        {
            return Get-CimInstance -ClassName Win32_Service -Filter "Name='$($this.Name)'"
        }
        catch
        {
            Write-Verbose "Error retrieving win32_service information for $($this.Name)"
            throw
        }
    }

    <#
    .Synopsis
    Normalizes startup type 
    #>
    hidden [string] NormalizeStartupType([string]$StartupType)
    {
        if ($StartupType -ieq 'Auto') {return "Automatic"}
        return $StartupType
    }
   
  #endregion Helper Methods

}

#region Test Helpers

function New-Service
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Position=1)]
        [string]
        $State,

        [Parameter(Position=2)]
        [string]
        $StartupType
    )
    $s = [Service]::new()
    $s.Name = $Name

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $s.State = $State
    }
    if ($PSBoundParameters.ContainsKey('StartupType'))
    {
        $s.StartupType = $StartupType
    }

    return $s 
} 


#endregion Test Helpers