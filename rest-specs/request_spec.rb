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
    create_user 'blind'
    auth_token = log_user_in

    create_request_url  = "#{@servername_with_credentials}/requests"
    RestClient.post create_request_url, {'auth_token'=> auth_token}.to_json

    wr = WaitingRequests.new
    requests = wr.get_waiting_requests_from_last  2.seconds.ago
    expect(requests.count).to eq(1)
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
