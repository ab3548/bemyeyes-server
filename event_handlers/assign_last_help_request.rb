require_relative './event_handler_base'
class AssignLastHelpRequest < EventHandlerBase
  def helper_notified(payload)
    @payload = payload
    helper.last_help_request = Time.now
    helper.save!
  end
end
