class CheckForInactiveUser
  def device_changed payload
    device_token = payload[:device_token]
    user = Device.first(device_token: device_token).user

    inactive = true
    user.devices.each do |device|
      unless device.inactive
        inactive = false
        break
      end
    end
    user.inactive = inactive
    user.save!
  end
end
