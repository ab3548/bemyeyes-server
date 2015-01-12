require_relative './rest_shared_context'

describe "Helpers" do
  include_context "rest-context"

  before(:each) do
    User.destroy_all
    Request.destroy_all
    HelperRequest.destroy_all
  end

  it "does not mark a cancelled request as waiting" do
    blind_token = create_blind_ready_to_make_request
    helper_token, helper_id = create_helper_ready_for_call
    request_id = create_request blind_token

    answer_request(request_id, helper_token)
    cancel_request(request_id, helper_token)

    waiting_request_id = get_waiting_request_id helper_id

    expect(waiting_request_id).to eq(0)
  end

  it "returns id of waiting requests" do
    blind_token = create_blind_ready_to_make_request
    _helper_token, helper_id = create_helper_ready_for_call

    request_id = create_request(blind_token)

    expect(HelperRequest.count(helper_id: helper_id)).to eq(1)

    waiting_request_id = get_waiting_request_id helper_id

    expect(waiting_request_id).to eq(request_id)
  end

  def get_waiting_request_id helper_id
    waiting_requests_url  = "#{@servername_with_credentials}/helpers/waiting_request/#{helper_id}"
    response = RestClient.get waiting_requests_url

    expect(response.code).to eq(200)

    jsn = JSON.parse response.body
    id = jsn['id']
    id
  end

  def create_blind_ready_to_make_request
    create_user 'blind'
    log_user_in
  end

  def create_helper_ready_for_call
    role ="helper"
    email = create_unique_email
    password = encrypt_password 'helperPassword'
    user_id, auth_token = create_user role, email, password
    log_user_in email, password
    register_device auth_token, 'device_token', 'iPhone'

    return auth_token, user_id
  end
end
