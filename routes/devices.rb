require 'active_support'
require 'active_support/core_ext'
class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/devices' do

    # Register device
    post '/register' do
      begin
        should_be_authenticated
        device_token = body_params["device_token"]
        device_name = body_params["device_name"]
        model = body_params["model"]
        system_version = body_params["system_version"]
        app_version = body_params["app_version"]
        app_bundle_version = body_params["app_bundle_version"]
        locale = body_params["locale"]
        development = body_params["development"]
        inactive= body_params["inactive"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      device = update_device(device_token, device_name, model, system_version, app_version, app_bundle_version, locale, development, inactive)

      unless inactive
        EventBus.publish(:device_created_or_updated, device_id:device.id)
      end
      return { "success" => true, "device_token" => device_token }.to_json
    end
  end # End namespace /devices

  def update_device(device_token, device_name, model, system_version, app_version, app_bundle_version, locale, development, inactive)

    device = Device.first(:device_token => device_token)
    unless device.nil?
      device.destroy
    end

    begin
      device = Device.new

      # Update information
      device.device_token = device_token
      device.device_name = device_name
      device.model = model
      device.system_version = system_version
      device.app_version = app_version
      device.app_bundle_version = app_bundle_version
      device.locale = locale
      device.development = development
      device.inactive = inactive

      current_user.devices.push(device)
      current_user.save!

      device.save!
      device
    rescue Exception => e
      give_error(400, ERROR_DEVICE_ALREADY_EXIST, "Error updating device").to_json
    end
  end
end
