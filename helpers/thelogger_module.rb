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
    logstash_logger.error message:message, backtrace: backtrace
    loggger.error message
  end

  def debug(message)
    logstash_logger.debug message:message
    loggger.debug message
  end

  def info(message)
    logstash_logger.info message:message
    loggger.info message
  end

  def warn(message)
    logstash_logger.warn message:message
    loggger.warn message
  end

  def fatal(message)
    logstash_logger.fatal message:message
    loggger.fatal message
  end
end


module TheLogger
  def self.log
    @log ||= BMELogger.new()
  end
end
