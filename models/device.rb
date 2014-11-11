class Device
  include MongoMapper::Document

  belongs_to :user, :class_name => "User"

  key :device_token, String, :required => true, :unique => true
  key :device_name, String
  key :model, String
  key :system_version, String
  key :app_version, String
  key :app_bundle_version, String
  key :locale, String
  key :development, Boolean, :default => false
  key :inactive, Boolean, :default => false

  key :auth_token, String, :unique => true
  key :expiry_time, Time

  timestamps!

  before_create :generate_token
  before_save :calculate_expiry_time

  def is_logged_in
    !auth_token.nil? && !inactive
  end

  def valid()
    return Time.now < self.expiry_date
  end

  def valid_time=(valid_time)
    @valid_time = valid_time
  end


  def to_json()
    return { "token" => self.auth_token, "expiry_time" => self.expiry_time.utc.iso8601 }.to_json
  end

  private
  def generate_token()
    self.auth_token = SecureRandom.urlsafe_base64(64, false)
  end

  def calculate_expiry_time()
    now = Time.now
    self.expiry_time = Time.new(now.year, now.month, now.day, 0, 0, 0) + @valid_time.to_i
  end
end
