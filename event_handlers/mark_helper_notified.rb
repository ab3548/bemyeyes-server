class MarkHelperNotified
  def helper_notified(payload)
    fiber = Fiber.new do

      request = payload[:request]
      helper = payload[:helper]
      HelperRequest.create! :request => request, :helper => helper
    end

    fiber.resume
  end
end
