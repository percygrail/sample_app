require 'reloader/sse'

class UsersController < ApplicationController
  include ActionController::Live

  before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :following, :followers]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: :destroy
  before_action :signed_out_user, only: [:new, :create]

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to the Sample App!"
      redirect_to @user
    else
      render 'new'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User destroyed"
    redirect_to users_url
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def notifications
    @title = "Notifications"
    @user = User.find(params[:id])
    render 'show_notifications'
  end

  def notify
    @user = User.find(params[:id])
    response.header['Content-Type'] = 'text/event-stream'
    sse = Reloader::SSE.new(response.stream)
    redis_client = Redis.new

    begin
      updates = 0

      redis_client.subscribe('relationship_updates') do |on|

        on.message do |event, data|

          updates += 1
          parsed_data = JSON.parse(data)

          #Rails.logger.debug("Action: " + parsed_data["action"] + "  Followed: " + parsed_data["followed_id"].to_s + "  Follower: " + parsed_data["follower_id"].to_s)
          newcount = 0
          if parsed_data["followed_id"] == @user.id

            User.uncached do
              newcount = @user.followers.count
            end

            Rails.logger.debug("\033[0;34mfollower update (#{newcount})\033[0;37m")
            #Rails.logger.debug("\033[0;34mFollowers: #{@user.followers.count}\033[0;37m")
            #Rails.logger.debug("\033[0;34mFollowing: #{@user.followed_users.count}\033[0;37m")

            sse.write({ :followers  => newcount }, { event: 'followers-update' })

          elsif parsed_data["follower_id"] == @user.id

            User.uncached do
              newcount = @user.followed_users.count
            end

            Rails.logger.debug("\033[0;34mfollowing update (#{newcount})\033[0;37m")
            #Rails.logger.debug("\033[0;34mFollowers: #{@user.followers.count}\033[0;37m")
            #Rails.logger.debug("\033[0;34mFollowing: #{@user.followed_users.count}\033[0;37m")

            sse.write({ :following => newcount }, { event: 'following-update' })

          end
        end
      end

    rescue IOError
    ensure
      redis_client.quit
      sse.close
    end
  end

  def following
    @title = "Following"
    @user = User.find(params[:id])
    @users = @user.followed_users.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "Followers"
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  # before filters

  def signed_out_user
    if signed_in?
      redirect_to root_url, notice: "Already signed up, Dude."
    end
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end

  def admin_user
    redirect_to(root_url) unless current_user.admin?
  end
end
