require_relative './../rest_shared_context'


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

end

