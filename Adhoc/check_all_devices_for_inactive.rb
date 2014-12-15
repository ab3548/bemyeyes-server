require './app.rb'

check_for_inactive_user = CheckForInactiveUser.new

Device.all.each do |device|
  unless device.nil? && device.user.nil?
    payload = {device_id: device.id}
    check_for_inactive_user.device_changed payload
    puts '.'
  end
end
