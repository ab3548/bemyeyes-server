class AssignLastHelpRequest
  def helper_notified(payload)
    fiber = Fiber.new do
      helper = payload[:helper]
      helper.last_help_request = Time.now
      helper.save!
    end

    fiber.resume
  end
end
