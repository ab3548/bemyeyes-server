#encoding: utf-8
# Give an error
def give_error(status_code, code, message)
  backtrace=get_stacktrace

  if !$!.nil? and !$!.message.nil?
    message += " " + $!.message
  end
  TheLogger.log.error(message, backtrace)
  halt(status_code, {"Content-Type" => "application/json"}, create_error_hash(code, message).to_json)
end
def logstash_logger
    @logstash_logger ||= LogStashLogger.new(type: :udp, host: 'localhost', port: 3334)
end
# Create error
def create_error_hash(code, message)
  return { "error" => {
             "code" => code,
             "message" => message
  } }
end


def get_stacktrace
  backtrace=''
  if !$@.nil?
    backtrace = $@.join("\n")
  end
  backtrace
end

