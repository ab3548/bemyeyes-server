require_relative './rest_shared_context'

describe "Request" do
  include_context "rest-context"

  before(:each) do
    User.destroy_all
    Blind.destroy_all
    Device.destroy_all
    Request.destroy_all
  end

  it "can create a request" do
    create_user 'blind'
    auth_token = log_user_in

    create_request_url  = "#{@servername_with_credentials}/requests"
    response = RestClient.post create_request_url, {'auth_token'=> auth_token}.to_json

    expect(response.code).to eq(200)
    jsn = JSON.parse(response.to_s)
    expect(jsn["id"]).to_not eq(nil)
  end

  it "create request and find it waiting" do
    pending("timing issue")
    create_user 'blind'
    auth_token = log_user_in

    create_request_url  = "#{@servername_with_credentials}/requests"
    RestClient.post create_request_url, {'auth_token'=> auth_token}.to_json

    wr = WaitingRequests.new
    requests = wr.get_waiting_requests_from_lasts_2_minutes
    expect(requests.count).to eq(1)
  end

  def create_request(auth_token)
    create_request_url  = "#{@servername_with_credentials}/requests"
    response = RestClient.post create_request_url, {'auth_token'=> auth_token}.to_json
    json = JSON.parse(response.body)
    json["short_id"]
  end

  def answer_request(short_id, helper_token)
    answer_request_url  = "#{@servername_with_credentials}/requests/#{short_id}/answer"
    RestClient.put answer_request_url, {'auth_token'=> helper_token}.to_json
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

  it "can answer request and helper is added" do
    create_user 'blind'
    token = log_user_in
    short_id = create_request token

    helper_token, helper_id = create_helper_ready_for_call

    answer_request short_id, helper_token


    expect(Request.first.helper_id).not_to be_nil
    expect(Request.count).to eq(1)
  end

  it "warns user that request is already answered" do
    create_user 'blind'
    token = log_user_in
    short_id = create_request token

    helper_token, helper_id = create_helper_ready_for_call

    answer_request short_id, helper_token
    
    
    #yeah I know its the same helper, but that is not important now
    expect{answer_request short_id, helper_token}.to raise_error(RestClient::BadRequest)
  end
end
