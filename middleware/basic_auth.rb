require_relative 'middleware_base'

module BME
  class BasicAuth < MiddlewareBase
    def initialize(app)
      $stdout.puts "BME::BasicAuth"
      @settings = YAML.load_file('config/config.yml')
      @app = app
    end
    def call(env)
      begin
        path = env["PATH_INFO"]
        $stdout.puts "BME::BasicAuth"
        $stdout.puts path
        logs_path = "/logs"
        path_regex = Regexp.new("^(#{logs_path}$)|^(#{logs_path}(/.*))$")
        if path =~ path_regex
          if authorized? env
        $stdout.puts "BME::BasicAuth authorized"
            @app.call(env)
          else
        $stdout.puts "BME::BasicAuth not authorized"
            headers = {'WWW-Authenticate'=>'Basic realm="Restricted Area"'}
            response = Rack::Response.new "Unauthorized", 401, headers

            response.finish
          end
        else
          @app.call(env)
        end
      rescue => e
        warn "Error in BME::BasicAuth middleware #{e.message} #{get_stacktrace}"
      end
    end

    private
    def authorized?(env)
      auth_config = @settings['authentication']
      @auth =  Rack::Auth::Basic::Request.new(env)
      if @auth.provided?
        $stdout.puts @auth.credentials
      end
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [auth_config['username'], auth_config['password']]
    end
  end
end

