require_relative '../helpers/mail_service'
require_relative '../helpers/mail_messages/reset_password_mail_message'
class App < Sinatra::Base
  register Sinatra::Namespace
  def create_reset_password_token user
    token = ResetPasswordToken.create
    token.user = user
    token.save!
    user.save!
    token
  end

  def user
    @user ||= User.first({:email => @email}) || give_error(400, ERROR_USER_NOT_FOUND, "User Not found")
  end

  namespace '/auth' do
     # Logout, thereby deleting the token
    put '/logout' do
      begin
        auth_token = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      device = device_from_auth_token(auth_token)
  
      begin
        device.inactive =true
        device.save!
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, e.message)
      end

      EventBus.publish(:user_logged_out, device_id:device.id) unless device.nil?
      return { "success" => true }.to_json
    end

    def get_device device_token
      
      if device_token.nil? or device_token.length == 0
        device = Device.new
        device.device_token = 'not registered yet'
        device.inactive = true
        device.valid_time = 365.days
        device.save!
        return device
      end

      device = Device.first(:device_token => device_token)
      if device.nil?
        raise "device not found"
      end
      device
    end
    # Login, thereby creating an new token
    post '/login' do
      begin
        device_token = body_params["device_token"]
        if device_token.nil?
          raise 'device token cannot be nil'
        end
        device = get_device device_token
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "#{e.message}. device_token:
          #{body_params["device_token"]}").to_json
      end

      secure_password = body_params["password"]
      user_id = body_params["user_id"]

      # We need either a password or a user ID to login
      if secure_password.nil? && user_id.nil?
        give_error(400, ERROR_INVALID_BODY, "Missing password or user ID.").to_json
      end

      # We need an e-mail to login
      if body_params['email'].nil?
        give_error(400, ERROR_INVALID_BODY, "Missing e-mail.").to_json
      end

      if !secure_password.nil?
        # Login using e-mail and password
        password = decrypted_password(secure_password)
        user = User.authenticate_using_email(body_params['email'], password)

        # Check if we managed to log in
        if user.nil?
          give_error(400, ERROR_USER_INCORRECT_CREDENTIALS, "No user found matching the credentials.").to_json
        end
      elsif !user_id.nil?
        # Login using user ID
        user = User.authenticate_using_user_id(body_params['email'], body_params['user_id'])

        # Check if we managed to log in
        if user.nil?
          give_error(400, ERROR_USER_FACEBOOK_USER_NOT_FOUND, "The Facebook user was not found.").to_json
        end
      end

      # We did log in, create auth_token
      device.valid_time = 365.days
      user.devices.push(device)

      device.save!

      EventBus.publish(:user_logged_in, device_id:device.id)
     
      return { "token" => JSON.parse(device.to_json), "user" => JSON.parse(device.user.to_json) }.to_json
    end

    # Login with a token
    put '/login/token' do
      begin
        auth_token = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      device = device_from_auth_token(auth_token)

      return { "user" => JSON.parse(device.user.to_json) }.to_json
    end

    post '/request-reset-password' do
      begin
        @email = body_params["email"]

        if user.is_external_user
          give_error(400, ERROR_NOT_PERMITTED, "external users can not have their passwords reset")
        end

        token = create_reset_password_token user

        EventBus.publish(:rest_password_token_created, token_id: token.id)

      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "Unable to create reset password token").to_json
      end
    end
  end
end
