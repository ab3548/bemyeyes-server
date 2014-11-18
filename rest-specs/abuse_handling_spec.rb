require_relative './rest_shared_context'

describe "abuse handling" do
  def create_request(auth_token, helper = nil) 
    user = User.first(auth_token:auth_token)
    session_id = 'session_id'
    request = Request.create
    request.short_id_salt = 'short_id_salt'
    request.session_id = session_id
    request.blind = user
    request.helper = helper
    request.answered = false
    request.token = user.auth_token
    request.save!
    request
  end
  include_context "rest-context"

  def report_abuse(auth_token, request_id)
    url = "#{@servername_with_credentials}/abuse/report"
    response = RestClient.post url,
      {'auth_token' =>auth_token, 'request_id'=>request_id, 'reason'=> 'abusive stuff'}.to_json

    expect(response.code).to eq(200)
  end

  before(:each) do
    User.destroy_all
  end

  it "will complain if no parameters are sent" do
    url = "#{@servername_with_credentials}/abuse/report"
    expect{ RestClient.post url, {}.to_json}
    .to raise_error(RestClient::Unauthorized)
  end

  it "will not accept a abuse report if reporter is  not logged in " do
    create_user 'blind'
    auth_token = log_user_in
    #we could add a helper and all to the request, but for this test we don't need it
    request = create_request auth_token

    #log user out
    logoutUser_url  = "#{@servername_with_credentials}/auth/logout"
    RestClient.put logoutUser_url, {'auth_token'=> auth_token + 'abc'}.to_json

    expect{report_abuse auth_token, request.id}
    .to raise_error(RestClient::Unauthorized)
  end

  it "will let user report abuse" do
    user_id = create_user 'blind'
    auth_token = log_user_in

    helper_user_id = create_user 'helper', 'helper@example.com'
    helper = User.first(:_id => helper_user_id)

    request = create_request auth_token, helper
    report_abuse auth_token, request.id
    helper.reload

    expect(helper.abuse_reports.count).to eq(1)
  end
end
