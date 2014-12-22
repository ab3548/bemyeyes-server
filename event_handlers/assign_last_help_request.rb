require_relative './event_handler_base'
class AssignLastHelpRequest < EventHandlerBase
  def helper_notified(payload)
    begin
      @payload = payload
      if helper.nil?
        TheLogger.log.error "helper nil in AssignLastHelpRequest"
      end
      helper.last_help_request = Time.now
      helper.save!
    rescue Exception => e
      rescue_with_handler(e)
    end
  end
end
