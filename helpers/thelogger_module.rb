require_relative 'ambient_request'

class BMELogger
 attr_accessor :level
 attr_accessor :formatter

  def loggger
    @log ||= Logger.new('log/app.log', 'daily')
  end

  def logstash_logger
    @logstash_logger ||= LogStashLogger.new(type: :udp, host: 'localhost', port: 3334)
  end

  def error(message, backtrace = nil)
    base_url = AmbientRequest.instance.request.base_url
    logstash_logger.error message:message, backtrace: backtrace, base_url:  base_url
    loggger.error message
  end

  def debug(message)
    base_url = AmbientRequest.instance.request.base_url
    logstash_logger.debug message:message, base_url:  base_url
    loggger.debug message
  end

  def info(message)
    base_url = AmbientRequest.instance.request.base_url
    logstash_logger.info message:message, base_url:  base_url
    loggger.info message
  end

  def warn(message)
    base_url = AmbientRequest.instance.request.base_url
    logstash_logger.warn message:message, base_url:  base_url
    loggger.warn message
  end

  def fatal(message)
    base_url = AmbientRequest.instance.request.base_url
    logstash_logger.fatal message:message, base_url:  base_url
    loggger.fatal message
  end
end


module TheLogger
  def self.log
    @log ||= BMELogger.new()
  end
end
