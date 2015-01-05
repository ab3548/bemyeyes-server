class App < Sinatra::Base
  register Sinatra::Namespace

  namespace '/abuse' do
    def check_and_raise_if_blank_string(theStr, name)
      if theStr.nil? or theStr.length == 0
        raise "#{name} can not be empty or nil "
      end
    end

    def get_reporter_role
      current_user.role
    end

    post '/report' do
      should_be_authenticated
      begin
        request_id = body_params["request_id"]
        reason = body_params["reason"]
        check_and_raise_if_blank_string request_id, "request_id"
        check_and_raise_if_blank_string reason, "reason"
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      begin
        reporter = get_reporter_role
        request = Request.first(id: request_id)
        
        EventBus.announce(:abuse_report_filed, request: request, reporter: reporter, reason:reason)
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "Unable to create abuse report").to_json
      end
    end
  end
end
