module Webdav
  #Startup determines from configuration which module to call
  class InvalidWebdavModule < ArgumentError; end

  # Follows one of two paths of execution:
  # Accepts a block but will execute in context of the module being loaded
  # Second it will return an instance of module loaded
  #
  # * *Args*    :
  #   - +mod+ -> Module name (string or const) to be loaded
  # * *Returns* :
  #   - +Webdav::Base+ -> Instance of Webdav::Base (or derivative)
  # * *Raises*  :
  #   - +Webdav::InvalidWebdavModule+ -> Indication that requested module
  #                                      is not correct for operation
  #
  def self.start_module(mod, &block)
    begin
      #If we're passed a string representation eg Webdav::Standard
      mod = mod.split('::').reduce(Module, :const_get) if mod.is_a?(String) #Convert string to object
      m = mod.new
    rescue
      m = Webdav::None.new
    end
    raise InvalidWebdavModule unless m.kind_of?(Webdav::Base)
    m.instance_eval(&block) if block_given?
    m # Return a reference to the module anyways
  end

  # Loads the module through start_module and then executes
  # procedures to initiate its mount into Rails routing engine
  # should that be so desired.
  #
  # * *Args*    :
  #   - None
  # * *Returns* :
  #   - +Webdav::Base+ -> Instance of Webdav::Base (or derivative)
  #
  def self.mount_from_config
    webdav_settings = Setting.plugin_redmine_dmsf[:webdav]
    return if webdav_settings.nil?
    m_to_load = webdav_settings[:provider]
    config_base = webdav_settings[:configuration] || {}
    self.start_module(m_to_load) do
      load_config config_base[m_to_load]
      rails_mount
    end
  end
end