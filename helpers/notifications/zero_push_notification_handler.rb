require 'zero_push'
require_relative './notification_handler'

module ZeroPushIphoneNotifier
  ZERO_PUSH_FIRST_VERSION = 33

  def init(zero_push_auth_token, logger)
    @zero_push_auth_token = zero_push_auth_token
    @logger = logger
  end

  def initialize_zero_push
    ZeroPush.auth_token = @zero_push_auth_token
    if !ZeroPush.verify_credentials
      raise 'ZERO>PUSH credentials not configured correctly'
    end
  end

  def send_notifications request, device_tokens
    fiber = Fiber.new do
      initialize_zero_push
      # Create notification
      user = request.blind
      notification_args_name = user.to_s
      notification = {
        :device_tokens => device_tokens,
        :alert => {
          :"loc-key" => "PUSH_NOTIFICATION_ANSWER_REQUEST_MESSAGE",
          :"loc-args" => [ notification_args_name ],
          :"action-loc-key" => "PUSH_NOTIFICATION_ANSWER_REQUEST_ACTION",
          :short_id => request.short_id,
        }, 
        :sound => "call.aiff",
        :badge => 1,
      }
      # Send notification
      ZeroPush.notify(notification)
    end

    fiber.resume

    device_tokens.each do |token|
      TheLogger.log.info("sending request to token device " + token)
    end
    TheLogger.log.info "Push notification handled by: " + self.class.to_s

  end

  def send_reset_notifications device_tokens
    fiber = Fiber.new do

      initialize_zero_push
      # Create notification
      notification = {
        :device_tokens => device_tokens,

        :badge => 0,
      }
      # Send notification
      ZeroPush.notify(notification)
    end

    fiber.resume

    device_tokens.each do |token|
      TheLogger.log.info("sending reset request to token device " + token)
    end
    TheLogger.log.info "Push notification handled by: " + self.class.to_s
  end


  def register_device(device_token, _options = {})
    begin
      fiber = Fiber.new do
        initialize_zero_push
        ZeroPush.register(device_token)
        TheLogger.log.info "Register device handled by: " + self.class.to_s
      end

      fiber.resume
    rescue Errno::ETIMEDOUT, Faraday::SSLError, Faraday::TimeoutError => e
      TheLogger.log.error "unable to register device with token #{device_token} #{e}"
      device = Device.first(:device_token => device_token)
      device.inactive = true
      device.save
    end

  end

  def unregister_device(device_token, _options = {})
    initialize_zero_push
    ZeroPush.unregister(device_token)
    TheLogger.log.info "UnRegister device handled by: " + self.class.to_s
  end

  def collect_feedback_on_inactive_devices
    initialize_zero_push
    ZeroPush.inactive_tokens().body.each() do |feedback|
      device_token = feedback['device_token']
      device = Device.first(:device_token => device_token)
      unless device.nil?
        device.inactive = true
        device.save!
        EventBus.publish(:device_inactive, device_id:device.id)
        TheLogger.log.info "device inactive: #{device_token}"
      end
    end
  end
end

class ZeroPushIphoneDevelopmentNotifier < NotificationHandler
  include ZeroPushIphoneNotifier

  def initialize(zero_push_auth_token, logger)
    init zero_push_auth_token, logger
  end

  def include_device? device
    device.development && device.system_version =~ /iPhone.*/
  end
end

class ZeroPushIphoneProductionNotifier < NotificationHandler
  include ZeroPushIphoneNotifier

  def initialize(zero_push_auth_token, logger)
    init zero_push_auth_token, logger
  end

  def include_device? device
    ! device.development && device.system_version =~ /iPhone.*/
  end
end
