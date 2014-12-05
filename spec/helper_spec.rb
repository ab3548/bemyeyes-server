require_relative './init'
require 'timecop'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
describe "Helper" do
  before do
    IntegrationSpecHelper.InitializeMongo()
  end
  before(:each) do
    User.destroy_all
    Device.destroy_all
    Request.destroy_all
  end

  describe "available" do
    it "can get available helpers with language" do
      Timecop.freeze(Time.gm(2014,"jul",9,11,30) ) do
        request = build(:request)

        helper = request.helper
        helper.languages = ['ab', 'en']
        helper.first_name = "non-english"
        helper.create_or_renew_token
        helper.save!

        blind =request.blind
        blind.languages = ['en', 'da']
        blind.save!

        expect(helper.available(request).count).to eq(1)
      end
    end

    it "finds no available helpers when noone speaks blind persons languages" do
      request = build(:request)

      helper = request.helper
      helper.languages = ['ab', 'aa']
      helper.first_name = "non-english"
      helper.save!

      blind =request.blind
      blind.languages = ['en', 'da']
      blind.save!


      expect(helper.available(request).count).to eq(0)
    end
  end

  describe "languages" do
    it "can create a Helper with two languages" do
      helper = build(:helper)
      helper.languages = ['ab', 'aa']
      helper.save!
    end

    it "finds no helpers when no speaks blind persons languages" do
      request = build(:request)

      helper = request.helper
      helper.languages = ['ab', 'aa']
      helper.first_name = "non-english"
      helper.save!

      blind =request.blind
      blind.languages = ['en']
      blind.save!

      expect(Helper.helpers_who_speaks_blind_persons_language(request).count).to eq(0)
    end

    it "finds a helpers when one language overlaps" do
      request = build(:request)

      helper = request.helper
      helper.languages = ['ab', 'en']
      helper.first_name = "non-english"
      helper.save!

      blind =request.blind
      blind.languages = ['en', 'da']
      blind.save!

      expect(Helper.helpers_who_speaks_blind_persons_language(request).count).to eq(1)
    end
  end
end
