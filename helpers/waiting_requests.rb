class WaitingRequests
  #http://stackoverflow.com/questions/2943222/find-objects-between-two-dates-mongodb
  def get_waiting_requests_from_last span
    Request.where(:stopped => false, :answered => false, :last_help_request.lt => span.utc).all
  end
end
