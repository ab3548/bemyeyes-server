class MarkHelperNotified
  def helper_notified(payload)
    TheLogger.log.error "///////////////////////////////////////////////////////////"
    TheLogger.log.error "create HelperRequest"
    request = payload[:request]
    helper = payload[:helper]
    HelperRequest.create! :request => request, :helper => helper
  end
end
