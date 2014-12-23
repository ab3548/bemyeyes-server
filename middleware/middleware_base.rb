module BME
  class MiddlewareBase

    def get_stacktrace
      backtrace=''
      if !$@.nil?
        backtrace = $@.join("\n")
      end
      backtrace
    end
  end
end
