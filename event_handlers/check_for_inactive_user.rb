class CheckForInactiveUser
  def device_changed payload
    device_id = payload[:device_id]
    user = Device.first(_id: device_id).user

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
