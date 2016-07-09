dsc_resource 'wuauserv' do
   resource :WindowsService
   module_name :ServiceManager
   property :name, 'wuauserv'
   property :state, 'stopped'
end