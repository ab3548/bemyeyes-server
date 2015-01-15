require_relative './rest_shared_context'


describe "smoketest" do
  include_context "rest-context"
 it "can get the logs" do
    url = "#{@servername_with_credentials}/log/"
    response = RestClient.get url
    expect(response.code).to eq(200)
  end
end
