class Helper < User
  many :helper_request, :foreign_key => :helper_id, :class_name => "HelperRequest"
  many :helper_points, :foreign_key => :user_id, :class_name => "HelperPoint"
  many :request, :foreign_key => :request_id, :class_name => "Request"
  key :user_level_id, ObjectId
  belongs_to :user_level, :class_name => 'UserLevel'
  key :role, String
  key :last_help_request, Time, :default=> Time.new(1970, 1, 1, 0, 0, 0, "+02:00") 

  before_create :set_role
  after_create :set_points
  before_save :set_user_level

  def set_points()
    if role == "helper"
      point = HelperPoint.signup
      self.helper_points.push point
    end
  end

  def set_role()
    self.role = "helper"
  end

  def set_user_level
    self.user_level = UserLevel.first(:point_threshold.lte => points, :order => :point_threshold.desc) 
  end

  def points
    self.helper_points.inject(0){|sum,x| sum + x.point }
  end

  def self.helpers_who_speaks_blind_persons_language request
    raise 'no blind person in call' if request.blind.nil?
    languages_of_blind = request.blind.languages
    TheLogger.log.info "languages_of_blind #{languages_of_blind}"
    Helper.where(:languages => {:$in => languages_of_blind})
  end

  def waiting_requests
    request_ids = HelperRequest
    .where(:helper_id => _id, :cancelled => false)
    .fields(:request_id)
    .all
    .collect(&:request_id)
    Request.all(:_id => {:$in =>request_ids}, :stopped => false, :answered  => false)
  end

  #TODO to be improved with snooze functionality
  def available request=nil, limit=5
    begin
      request_id = request.present? ? request.id : nil
      contacted_helpers = HelperRequest
      .where(:request_id => request_id)
      .fields(:helper_id)
      .all
      .collect(&:helper_id)
      TheLogger.log.debug "contacted_helpers #{contacted_helpers}"

      logged_in_users = User
      .where(:expiry_time.gt => Time.now)
      .fields(:_id)
      .all
      .collect(&:_id)
      TheLogger.log.debug "logged_in_users #{logged_in_users}"

      abusive_helpers = User
      .where('abuse_reports.blind_id' => request.blind_id)
      .fields(:_id)
      .all
      .collect(&:_id)
      TheLogger.log.debug "abusive_helpers #{abusive_helpers}"

      blocked_users = User
      .where(:blocked => true)
      .fields(:user_id)
      .all
      .collect(&:user_id)
      TheLogger.log.debug "blocked_users #{blocked_users}"

      asleep_users = User.asleep_users
      .where(:role=> 'helper')
      .fields(:user_id)
      .all
      .collect(&:user_id)
      TheLogger.log.debug "asleep_users #{asleep_users}"

      helpers_who_speaks_blind_persons_language = Helper.helpers_who_speaks_blind_persons_language(request)
      .fields(:user_id)
      .all
      .collect(&:user_id)
      TheLogger.log.debug "helpers_who_speaks_blind_persons_language #{helpers_who_speaks_blind_persons_language}"

      helpers_in_a_call = Request.running_requests
      .fields(:helper_id)
      .all
      .collect(&:helper_id)
      TheLogger.log.debug "helpers_in_a_call #{helpers_in_a_call}"

    rescue Exception => e
      TheLogger.log.error e.message
    end

    Helper.where(
      :id.nin => contacted_helpers,
      "$or" => [
        {:available_from => nil},
        {:available_from.lt => Time.now.utc}
    ])
    .where(:user_id.nin => asleep_users)
    .where(:id.nin => abusive_helpers)
    .where(:id.in => logged_in_users)
    .where(:user_id.nin => blocked_users)
    .where(:user_id.in => helpers_who_speaks_blind_persons_language)
    .where(:user_id.nin => helpers_in_a_call)
    .sort(:last_help_request.desc)
    .all.sample(limit)
  end
end
