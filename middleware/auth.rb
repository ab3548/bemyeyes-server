require 'uri'

module BME
  class Auth
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        $stdout.puts '--------------------------------------------------------'
        url = env['PATH_INFO']
        method = env['REQUEST_METHOD']
        $stdout.puts "url #{method} #{url}"
        if method =~ /(POST|PUT)/
          env['authenticated'] = false
          input = JSON.parse env['rack.input'].read
          $stdout.puts "input in middleware #{input}"
          auth_token = input['auth_token']
          load_user auth_token, env
        elsif method =~ /GET/
          #ok kinda bad convention, but if get and auth, let last part be auth_token
          auth_token = URI(url).path.split('/').last
          $stdout.puts "input in middleware #{auth_token}"
          load_user auth_token, env
        end

      rescue => e
        $stderr.puts "Error in BME::Auth middleware #{e.message}"
      end
      @app.call(env)
    end

    def load_user auth_token, env
      unless auth_token.nil?
        user = User.first(:auth_token => auth_token)
        unless user.nil?
          $stdout.puts "user #{user}"
          env['current_user'] = user
          env['authenticated'] = true
        end
      end
    end
  end
end
