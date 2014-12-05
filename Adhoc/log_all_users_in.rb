require './app.rb'
User.all.each do |user|

  if user.auth_token.nil?
    user.auth_token = SecureRandom.urlsafe_base64(64, false)
  end

  if user.expiry_time.nil?
    now = Time.now
    user.expiry_time = Time.new(now.year, now.month, now.day, 0, 0, 0) + 365.days.to_i
  end
end