require 'reloader/sse'
class StaticPagesController < ApplicationController
  include ActionController::Live
  def home
    if signed_in?
      @micropost = current_user.microposts.build
      @feed_items = current_user.feed.paginate(page: params[:page])
    end
  end

  def help
  end

  def about
  end

  def contact
  end

  def notifications
    @title = "Notifications"
    render 'show_notifications'
  end

  def notify
    response.header['Content-Type'] = 'text/event-stream'
    sse = Reloader::SSE.new(response.stream)
    begin
      seconds = 0
      loop do
        sse.write({ :time => Time.now }, { event: 'TimeUpdate' })
        sse.write({ :seconds => seconds }, { event: 'SecondsUpdate' })
        sleep 1
        seconds += 1
      end
    rescue IOError
    ensure
      sse.close
    end
  end

end
