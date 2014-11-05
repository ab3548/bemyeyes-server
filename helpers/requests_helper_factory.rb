require_relative './requests_helper'

class RequestsHelperFactory
  def self.create settings
    environment = settings.config['environment']
    zero_push_config = settings.config['zero_push'][environment]
    RequestsHelper.new zero_push_config, TheLogger
  end
end
