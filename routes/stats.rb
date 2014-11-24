require "sinatra/jsonp"

class App < Sinatra::Base
  register Sinatra::Namespace
  helpers Sinatra::Jsonp
  namespace '/stats' do
    get '/community' do
      return jsonp ({ 'blind' => Blind.count, 'helpers' => Helper.count, 'no_helped' =>Request.count })
    end

    get '/profile/:auth_token' do
       begin
      no_helped = Request.count(:helper_id => current_helper._id, :answered => true)
      total_points = current_helper.points
      events = get_point_events current_helper
      current_level =  user_level_to_BMELevel current_helper.user_level
      next_level = user_level_to_BMELevel current_helper.user_level.next_user_level

      return {'no_helped' => no_helped, 'total_points' => total_points, 'events' => events, 'current_level'=> current_level, 'next_level' => next_level}.to_json
       rescue => e
        give_error(400, ERROR_INVALID_BODY, "#{e.message}").to_json
      end
    end

    post '/event' do
      begin
      event = body_params['event']

      unless HelperPoint.point_type_exists? event.to_s
        give_error(400, ERROR_INVALID_BODY, "Event not found").to_json
      end

      # these events can only be registered once
      if current_helper.helper_points.any? { | point | point.message == event }
        give_error(400, ERROR_NOT_PERMITTED, "Event already registred").to_json
      end

      point = HelperPoint.send(event)
      current_helper.helper_points.push point
      current_helper.save
       rescue => error
        give_error(400, ERROR_INVALID_BODY, "Error").to_json
      end
      {:status => "OK"}.to_json
    end

    get '/actionable_tasks/:auth_token' do
      begin
        completed_point_events = get_point_events current_helper
        all_point_events = get_points_events_from_hash HelperPoint.actionable_points

        remaining_tasks = 
        all_point_events.select do |point|
           not completed_point_events.any? { | completed_point | completed_point.event== point.event}
        end

        completed_tasks =
        completed_point_events.select do |point|
           all_point_events.any? { | completed_point | completed_point.event == point.event}
        end

        BMERemainingTasks.new(remaining_tasks, completed_tasks).to_json
      rescue
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
    end
  end
class BMERemainingTasks< Struct.new(:remaining_tasks, :completed_tasks)
end

  class BMEPointEvent < Struct.new(:event, :date, :point)
  end

  class BMELevel < Struct.new(:title, :threshold)
  end

  def user_level_to_BMELevel user_level
    BMELevel.new(user_level.name, user_level.point_threshold)
  end

  def get_points_events_from_hash points_hash
    events = points_hash.collect{| message, point | BMEPointEvent.new(message, nil, point)}
    events
  end

  def get_point_events helper
    helper.helper_points.sort(:created_at.desc).collect{|point| BMEPointEvent.new(point.message,  point.log_time, point.point)}
  end
end
