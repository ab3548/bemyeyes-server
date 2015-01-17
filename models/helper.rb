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
      raise 'no blind person in call' if request.blind.nil?

      request_id = request.present? ? request.id : nil
      contacted_helpers = HelperRequest
      .where(:request_id => request_id)
      .fields(:helper_id)
      .all
      .collect(&:helper_id)
      TheLogger.log.debug "contacted_helpers #{contacted_helpers}"

       asleep_users = User.asleep_users
      .where(:role=> 'helper')
      .fields(:user_id)
      .all
      .collect(&:user_id)
      TheLogger.log.debug "asleep_users #{asleep_users}"

      languages_of_blind = request.blind.languages
      TheLogger.log.info "languages_of_blind #{languages_of_blind}"
      Helper.where(:languages => {:$in => languages_of_blind})

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
    .where('abuse_reports.blind_id' => {"$ne" =>  request.blind_id})
    .where(:expiry_time.gt => Time.now)
    .where(:blocked => false)
    .where(:languages => {:$in => languages_of_blind})
    .where(:user_id.nin => helpers_in_a_call)
    .where(:inactive => false)
    .sort(:last_help_request.asc)
    .all.sample(limit)
  end
end
