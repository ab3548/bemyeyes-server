require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require 'factory_girl'
require 'uri'
require 'growl-rspec'
require_relative '../app'
require_relative '../models/init'
require_relative '../spec/integration_spec_helper'
require_relative '../spec/factories'

I18n.config.enforce_available_locales=false
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.formatter = 'Growl::RSpec::Formatter'
end

# http://robots.thoughtbot.com/validating-json-schemas-with-an-rspec-matcher
RSpec::Matchers.define :match_response_schema do |schema|
  match do |response|
    schema_directory = "#{Dir.pwd}/rest-specs/support/api-schemas"
    schema_path = "#{schema_directory}/#{schema}.json"
    JSON::Validator.validate!(schema_path, response.body, strict: true)
  end
end

shared_context "rest-context" do
  before(:each) do
    config = YAML.load_file('config/config.yml')
    @username = config['authentication']['username']
    @password = config['authentication']['password']
    @security_salt = config["security_salt"]
    @servername = "http://localhost:3001"
    @servername_with_credentials = "http://#{@username}:#{@password}@localhost:3001"
    @email =  create_unique_email

    @password = encrypt_password('Password1')

    User.destroy_all
    Device.destroy_all
    HelperPoint.destroy_all
    HelperRequest.destroy_all
    Request.destroy_all
    ResetPasswordToken.destroy_all
  end

  def create_user role ="helper", email = @email, password = @password
    createUser_url = "#{@servername_with_credentials}/users/"
    response = RestClient.post createUser_url, {'first_name' =>'first_name',
                                                'last_name'=>'last_name', 'email'=> email,
                                                'role'=> role, 'password'=> password }.to_json

    jsn = JSON.parse response.body
    id = jsn['id']
    auth_token = jsn['auth_token']
    return id, auth_token
  end

  def create_helper_ready_for_call
    device_token = 'Helper device token'
    device_system_version ='iPhone for test'
    role ="helper"
    email = create_unique_email
    password = encrypt_password 'helperPassword'
    user_id, auth_token= create_user role, email, password
    log_user_in email, password
    register_device auth_token, device_token, device_system_version

    token = log_user_in email, password

    return token, user_id
  end
  
  def create_request(auth_token)
    create_request_url  = "#{@servername_with_credentials}/requests"
    response = RestClient.post create_request_url, {'auth_token'=> auth_token}.to_json
    json = JSON.parse(response.body)
    json["short_id"]
  end

  def answer_request short_id, auth_token
    answer_request_url  = "#{@servername_with_credentials}/requests/#{short_id}/answer"
    RestClient.put answer_request_url, {'auth_token'=> auth_token}.to_json
  end

  def cancel_request short_id, auth_token
    cancel_request_url  = "#{@servername_with_credentials}/requests/#{short_id}/answer/cancel"
    RestClient.put cancel_request_url, {'auth_token'=> auth_token}.to_json
  end

  def create_unique_email
    "user_#{(Time.now.to_f*100000).to_s}@example.com"
  end

  def encrypt_password password
    AESCrypt.encrypt(password, @security_salt)
  end

  def log_user_in email = @email, password = @password
    #log user in
    loginUser_url = "#{@servername_with_credentials}/auth/login"
    response = RestClient.post loginUser_url, {'email' => email, 'password'=> password}.to_json
    jsn = JSON.parse(response.to_s)
    token = jsn["auth_token"]
    token
  end

  def register_device auth_token = 'auth_token', device_token = 'device_token', system_version = 'system_version'
    url = "#{@servername_with_credentials}/devices/register"
    response = RestClient.post(url, {
      'device_token'=>device_token, 'device_name'=> 'device_name',
      'model'=> 'model', 'system_version' => system_version,
      'app_version' => 'app_version', 'app_bundle_version' => 'app_bundle_version',
      'locale'=> 'locale', 'development' => 'true'}.to_json,
      {'X_BME_AUTH_TOKEN' => auth_token})
    expect(response.code).to eq(200)
    json = JSON.parse(response.body)
    json["device_token"]
  end
end
