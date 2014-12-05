require './app.rb'
User.all.each do |user|

    user.auth_token = SecureRandom.urlsafe_base64(64, false)

    now = Time.now
    user.expiry_time = Time.new(now.year, now.month, now.day, 0, 0, 0) + 365.days.to_i
    user.save
end