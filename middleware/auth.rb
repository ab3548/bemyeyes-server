require 'uri'
require_relative 'middleware_base'

module BME
  class Auth < MiddlewareBase
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        print '--------------------------------------------------------'
        url = env['PATH_INFO']
        method = env['REQUEST_METHOD']
        print "url #{method} #{url}"
        if method =~ /(POST|PUT)/
          env['authenticated'] = false

          auth_token = get_auth_token_from_http_header env
          if auth_token.blank?
            auth_token = get_param_from_rack_input env, 'auth_token'
          end
          if auth_token.blank?
            auth_token = get_auth_token_from_query_string url
          end
          load_user auth_token, env
        elsif method =~ /GET/
          #ok kinda bad convention, but if get and auth, let last part be auth_token
          auth_token = get_auth_token_from_query_string url
          load_user auth_token, env
        end

      rescue => e
        warn "Error in BME::Auth middleware #{e.message} #{get_stacktrace}"
      end
      @app.call(env)
    end

    def get_param_from_rack_input env, param_name
      input = JSON.parse env['rack.input'].read
      env['rack.input'].rewind
      value = input[param_name]
      value
    end

    def get_auth_token_from_query_string url
      auth_token = URI(url).path.split('/').last
      auth_token
    end

    def get_auth_token_from_http_header env
      auth_token = env['HTTP_X_BME_AUTH_TOKEN']
      auth_token
    end

    def load_user auth_token, env
      unless auth_token.nil?
        user = User.first(auth_token: auth_token)
        unless user.nil?
          print "user #{user}"
          env['current_user'] = user
          env['authenticated'] = true
        end
      end
    end
  end
end
