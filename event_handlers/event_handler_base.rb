class EventHandlerBase
  include ActiveSupport::Rescuable
  rescue_from StandardError, with: :known_error

  def helper
    @helper ||= @payload[:helper]
    return @helper unless @helper.nil?
    @helper ||= Helper.first(_id: @payload[:helper_id])
    @helper
  end

  def request
    @request ||= @payload[:request]
    return @request unless @request.nil?
    @request ||= Request.first(_id: @payload[:request_id])
    @request
  end

  protected
  def known_error(error)
    TheLogger.log.error "event_handler error #{error.message} #{error.backtrace}"
  end
end
