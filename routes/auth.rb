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
      unless current_user.nil?
        current_user.reset_expiry_time
        current_user.save!
        EventBus.publish(:user_logged_out, device_id:current_user.id) unless current_user.nil?
        return { "success" => true }.to_json
      end
      return { "success" => false, "reason"=> "no current_user" }.to_json
    end

    # Login, thereby creating an new token
    post '/login' do
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

      user.create_or_renew_token
      user.save!
      return user.to_json
    end

    # Login with a token
    put '/login/token' do
      should_be_authenticated
      current_user.create_or_renew_token
      current_user.save!
     return current_user.to_json
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
