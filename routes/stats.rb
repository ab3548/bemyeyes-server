class App < Sinatra::Base
  register Sinatra::Namespace
  namespace '/stats' do
    get '/community' do

      return { 'blind' => Blind.count, 'helpers' => Helper.count, 'no_helped' =>Request.count }.to_json
    end

    get '/profile/:token_repr' do
      token_repr = params[:token_repr]
      helper = helper_from_token token_repr

      no_helped = Request.count(:helper_id => helper._id, :answered => true)
      total_points = helper.points
      events = get_point_events helper
      current_level =  user_level_to_BMELevel helper.user_level
      next_level = user_level_to_BMELevel helper.user_level.next_user_level 

      return {'no_helped' => no_helped, 'total_points' => total_points, 'events' => events, 'current_level'=> current_level, 'next_level' => next_level}.to_json
    end
  end
  
  class BMEPointEvent < Struct.new(:title, :date, :point)
  end

  class BMELevel < Struct.new(:title, :threshold)
  end

  def user_level_to_BMELevel user_level
    BMELevel.new(user_level.name, user_level.point_threshold)
  end

  def get_point_events helper

    events = helper.helper_points.collect{|point| BMEPointEvent.new(point.message,  point.log_time, point.point)}
    events
  end
end
