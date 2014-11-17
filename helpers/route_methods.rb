class App < Sinatra::Base
   before do
      next unless request.post? || request.put?
      begin
       @body_params = JSON.parse(request.body.read)
     rescue  => e
        TheLogger.log.error "Could not parse body as JSON #{e.message}"
     end
    end

    def body_params
      @body_params
    end

  def user_from_auth_token auth_token
    device = device_from_auth_token(auth_token)
    user = device.user
    user
  end

def helper_from_auth_token auth_token
    device = device_from_auth_token(auth_token)
    user = device.user

    helper = Helper.first(:_id => user._id)
    helper
  end


  def device_from_auth_token(auth_token)
    device = Device.first(:auth_token => auth_token)
    if device.nil?
      give_error(400, ERROR_USER_TOKEN_NOT_FOUND, "Device not found.").to_json
    end

    if !device.valid?
      give_error(400, ERROR_USER_TOKEN_EXPIRED, "Device login has expired.").to_json
    end

    return device
  end

   def helper_from_id(user_id)
    model_from_id(user_id, Helper, ERROR_USER_NOT_FOUND, "No helper found.")
  end

  def user_from_id(user_id)
    model_from_id(user_id, User, ERROR_USER_NOT_FOUND, "No user found.")
  end

  def model_from_id(id, model_class, code, message)
    model = model_class.first(:_id => id)
    if model.nil?
      give_error(400, code, message).to_json
    end
    
    return model
  end
end
