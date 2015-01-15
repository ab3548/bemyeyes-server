class App < Sinatra::Base
  before do
    next unless request.post? || request.put?
    begin
      unless request.body.nil?
        body_as_string = request.body.read
        if body_as_string.length != 0
          request.body.rewind
           @body_params = JSON.parse(body_as_string)
        end
        
      end
    rescue  => e
      TheLogger.log.error "Could not parse body as JSON #{e.message}"
    end
  end

  def body_params
    @body_params
  end

  def should_be_authenticated
    unless is_authenticated? && current_user.is_logged_in?
      give_error(401, ERROR_NOT_AUTHORIZED, "User not authenticated, please send auth_token")
    end
  end

  def is_authenticated?
    env['authenticated']
  end

  def current_user
    env["current_user"]
  end

  def current_helper
    helper = Helper.first(:_id => current_user._id)
    helper
  end
 
  def helper_from_id(user_id)
    model_from_id(user_id, Helper, ERROR_USER_NOT_FOUND, "No helper found.")
  end

  def user_from_id(user_id)
    model_from_id(user_id, User, ERROR_USER_NOT_FOUND, "No user found.")
  end

  def model_from_id(id, model_class, code, message)
    TheLogger.log.fatal "in model_from_id"
    model = model_class.first(:_id => id)
    if model.nil?
      give_error(400, code, message).to_json
    end

    return model
  end
end
