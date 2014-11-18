class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin users namespace
  namespace '/users' do
    def validate_body_for_create_user
      begin
        required_fields = {"required" => ["email", "first_name", "last_name", "role"]}
        schema = User::SCHEMA.merge(required_fields)
        JSON::Validator.validate!(schema, body_params)
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
    end

    # Create new user
    post '/?' do
      validate_body_for_create_user
      user = case body_params["role"].downcase
      when "blind"
        Blind.new
      when "helper"
        Helper.new
      else
        give_error(400, ERROR_UNDEFINED_ROLE, "Undefined role.").to_json
      end
      if !body_params['password'].nil?
        password = decrypted_password(body_params['password'])
        user.update_attributes body_params.merge({ "password" => password })
      elsif !body_params['user_id'].nil?
        user.update_attributes body_params.merge({ "user_id" => body_params['user_id'] })
        user.is_external_user = true
      else
        give_error(400, ERROR_INVALID_BODY, "Missing parameter 'user_id' for registering a Facebook user or parameter 'password' for registering a regular user.").to_json
      end
      begin
        user.reset_expiry_time
        user.save()
        user.reload
      rescue Exception => e
        give_error(400, ERROR_USER_EMAIL_ALREADY_REGISTERED, "The e-mail is already registered.").to_json if e.message.match /email/i
      end
      EventBus.announce(:user_created, user_id: user.id)
      return user_from_id(user.id).to_json
    end

    # Get user by id
    get '/:user_id' do
      content_type 'application/json'

      return user_from_id(params[:user_id]).to_json
    end

    get '/helper_points/:user_id' do
      days = params[:days]|| 30
      helper = helper_from_id(params[:user_id])

      days = days.to_i

      sums = HelperPointDateHelper.get_aggregated_points_for_each_day(helper, days)

      return sums.to_json
    end

    get '/helper_points_sum/:user_id' do
      retval = OpenStruct.new
      helper = helper_from_id(params[:user_id])
      if(helper.helper_points.count == 0)
        retval.sum = 0
        return retval.marshal_dump.to_json
      end
      retval.sum = helper.helper_points.inject(0){|sum,x| sum + x.point }
      return retval.marshal_dump.to_json
    end

    # Update a user
    put '/:user_id' do
      user = user_from_id(params[:user_id])
      begin
        JSON::Validator.validate!(User::SCHEMA, body_params)
        user.update_attributes!(body_params)
      rescue Exception => e
        puts e.message
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
      EventBus.announce(:user_updated, user: user)
      return user
    end

    def is_24_hour_string the_str
      !the_str.nil? and /\d\d:\d\d/.match the_str
    end

    put '/info/:auth_token' do
      should_be_authenticated
      begin
        current_user.wake_up = body_params['wake_up'] if is_24_hour_string body_params['wake_up']
        current_user.go_to_sleep = body_params['go_to_sleep'] if is_24_hour_string body_params['go_to_sleep']
        current_user.utc_offset = body_params['utc_offset'] unless body_params['utc_offset'].nil? or not /-?\d{1,2}/.match body_params['utc_offset']

        current_user.save!
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
    end

    put '/:user_id/snooze/:period' do
      puts params[:period]
      raise Sinatra::NotFound unless params[:period].match /^(1h|3h|1d|3d|1w|stop)$/
      user = user_from_id(params[:user_id])
      #Stores it in UTC, perhaps change it using timezone info later on.
      current_time = Time.now.utc
      #TODO refactor this case...
      new_time = case params[:period]
        when '1h'
          current_time + 1.hour
        when '3h'
          current_time + 3.hour
        when '1d'
          current_time + 1.day
        when '3d'
          current_time + 3.day
        when '1w'
          current_time + 1.week
        when 'stop'
          current_time
      end
      user.update_attributes!({:snooze_period => params[:period], :available_from => new_time})
      return user.to_json
    end
  end # End namespace /users
  
  # Decrypt the password
  def decrypted_password(secure_password)
    begin
      return AESCrypt.decrypt(secure_password, settings.config["security_salt"])
    rescue Exception => e
      give_error(400, ERROR_INVALID_PASSWORD, "The password is invalid.").to_json
    end
  end

end
