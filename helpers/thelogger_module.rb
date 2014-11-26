require 'logstash-logger'
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
    logstash_logger.error message:message, backtrace: backtrace, base_url:  base_url, url: url
    loggger.error message
  end

  def debug(message)
    logstash_logger.debug message:message, base_url:  base_url
    loggger.debug message
  end

  def info(message)
    logstash_logger.info message:message, base_url:  base_url
    loggger.info message
  end

  def warn(message)
    logstash_logger.warn message:message, base_url:  base_url
    loggger.warn message
  end

  def fatal(message)
    logstash_logger.fatal message:message, base_url:  base_url
    loggger.fatal message
  end
end


module TheLogger
  def self.log
    @log ||= BMELogger.new()
  end
end
