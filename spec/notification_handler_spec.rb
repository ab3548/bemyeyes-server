require_relative './init'
require_relative '../helpers/notifications/zero_push_notification_handler'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe NotificationHandler do
  def setup_logger
    log_instance_double = double('logger instance')
    allow(log_instance_double).to receive(:info)
    logger_double = double('logger')
    allow(logger_double).to receive(:log).and_return(log_instance_double)
    logger_double
  end

  before do
    IntegrationSpecHelper.InitializeMongo()
  end

  before(:each) do
    Device.destroy_all
  end

  describe "ZeroPushIphoneProductionNotifier" do
    it "Does not call development devices" do
      device = build(:device)
      device.development = true
      device.system_version = 'iPhonex'
      device.save!

      devices = Array.new
      devices << device

      request = build(:request)
      request.save!

      successor_double = double('successor')
      #should be called since it was not handled by the production notifier
      expect(successor_double).to receive(:handle_notifications) do |devices, request|
      end

      logger_double = setup_logger
      hash = Hash.new
      sut = ZeroPushIphoneProductionNotifier.new hash, logger_double
      sut.set_successor successor_double
      sut.handle_notifications devices, request
    end

     it "Does not call zero_push devices" do
      device = build(:device)
      device.development = true
      device.system_version = 'iPhonex'
      device.save!

      devices = Array.new
      devices << device

      request = build(:request)
      request.save!

      successor_double = double('successor')
      #should be called since it was not handled by the urban airship production notifier
      expect(successor_double).to receive(:handle_notifications) do |devices, request|
      end

      logger_double = setup_logger
      hash = Hash.new
      sut = ZeroPushIphoneProductionNotifier.new hash, logger_double
      sut.set_successor successor_double
      sut.handle_notifications devices, request
    end
  end

  it "filters out inactive devices" do
    device = build(:device)
    device.inactive = true
    device.save!

    devices = Array.new
    devices << device

    request = build(:request)
    request.save!

    successor_double = double('successor')
    #should not be called since the only device existing is inactive
    expect(successor_double).to_not receive(:handle_notifications) do |devices, request|
    end

    logger_double = setup_logger
    hash = Hash.new
    sut = ZeroPushIphoneProductionNotifier.new hash, logger_double
    sut.set_successor successor_double
    sut.handle_notifications devices, request
  end

end
