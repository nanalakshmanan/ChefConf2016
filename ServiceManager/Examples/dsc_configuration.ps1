configuration default
{
    Import-DscResource -Name WindowsService -ModuleName ServiceManager
    
    WindowsService wuauserv
    {
        Name        =   'wuauserv'
        State       =   'Stopped'
        StartupType = 'Manual'
    }
}