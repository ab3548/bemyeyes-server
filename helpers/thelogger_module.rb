require_relative 'ambient_request'

class BMELogger
 attr_accessor :level
 attr_accessor :formatter

  def loggger
    @log ||= Logger.new('log/app.log', 'daily')
  end

  def url
    ambient_request = AmbientRequest.instance.request
    unless ambient_request.nil?
      return ambient_request.url
    end
    "unit test"
  end

  def base_url
    ambient_request = AmbientRequest.instance.request
    unless ambient_request.nil?
      return ambient_request.base_url
    end
    "unit test"
  end

  def error(message, backtrace = nil)
    loggger.error message
  end

  def debug(message)
    loggger.debug message
  end

  def info(message)
    loggger.info message
  end

  def warn(message)
    loggger.warn message
  end

  def fatal(message)
    loggger.fatal message
  end
end


module TheLogger
  def self.log
    @log ||= BMELogger.new()
  end
end
