require 'rest_client'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'

require_relative '../app'
require_relative '../models/device'
require_relative '../models/user'
require_relative './rest_shared_context'
require_relative '../spec/integration_spec_helper'

describe "log user in" do
  include_context "rest-context"

  it "can log user in without device token" do
    #create user
    create_user
    #log user in
    loginUser_url = "#{@servername_with_credentials}/auth/login"
    expect{RestClient.post loginUser_url,
           {'email' => @email, 'password'=> @password}.to_json}
    .to_not raise_error
  end

  it "can log a user in, auth_token assigned to user and user logged in" do
    create_user
    auth_token = log_user_in
    user = User.first(:auth_token => auth_token)
    expect(user).to_not eq(nil)
    expect(user.is_logged_in?).to eq(true)
  end

  it "create user without login, user not logged in" do
    id, auth_token = create_user
    user = User.first(:auth_token => auth_token)
    expect(user.is_logged_in?).to eq(false)
  end

  it "can log user out with auth_token" do
   create_user
    auth_token = log_user_in
    user = User.first(:auth_token => auth_token)
    expect(user).to_not eq(nil)
    expect(user.is_logged_in?).to eq(true)

    logoutUser_url  = "#{@servername_with_credentials}/auth/logout"
    response = RestClient.put logoutUser_url, {'auth_token'=> auth_token}.to_json

    user = User.first(:auth_token => auth_token)
    expect(user.is_logged_in?).to eq(false)

  end
end
