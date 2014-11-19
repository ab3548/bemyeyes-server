require_relative './rest_shared_context'

describe "device update" do
  include_context "rest-context"
  UPDATEDMODEL = 'update_model'

  before(:each) do
    Device.destroy_all
  end

  def  update_device auth_token, device_token = 'device_token', new_device_token = 'new_device_token'
    url = "#{@servername_with_credentials}/devices/register"
    response = RestClient.post url, {'auth_token' =>auth_token,
                                     'device_token'=> device_token, 'new_device_token' => new_device_token, 'device_name'=> 'device_name',
                                     'model'=> UPDATEDMODEL, 'system_version' => 'system_version',
                                     'app_version' => 'app_version', 'app_bundle_version' => 'app_bundle_version',
                                     'locale'=> 'locale', 'development' => 'true'}.to_json
    expect(response.code).to eq(200)
    json = JSON.parse(response.body)
    json["token"]
  end
  it "can update a device" do
    id, auth_token = create_user
    log_user_in
    device_token = register_device auth_token
    update_device auth_token

    expect(Device.where(:model => UPDATEDMODEL).count).to eq(1)
  end


  it "can register a device sending auth_token in http header" do
     id, auth_token = create_user
    log_user_in
    device_token = register_device auth_token

    expect(Device.where(:device_token => device_token).count).to eq(1)
  end

  it "will not allow two devices with same device_token" do
    my_device_token = "my very special device token"
    id, auth_token = create_user
    log_user_in
    register_device auth_token, my_device_token
    register_device auth_token, my_device_token

    expect(Device.where(:device_token => my_device_token).count).to eq(1)
  end
end
