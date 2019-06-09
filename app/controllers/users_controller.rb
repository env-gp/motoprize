class UsersController < ApplicationController

  include Admin_common

  before_action :require_admin, only: [:index, :destroy]
  before_action :correct_user_check, only: [:edit, :update]

  skip_before_action :login_required, only: [:new, :create]
 
  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @likes = Like.likes(params[:page], @user)
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)

    if @user.save
      if cookies[:user_remember_token]
        redirect_to users_path, notice: "ユーザ「#{@user.name}」を登録しました。"
      else
        # セッションが存在しない場合、新規登録と見なしてrootに遷移する
        sign_in(@user)
        redirect_to root_path, notice: "ユーザ「#{@user.name}」を登録しました。"
      end
    else
      render :new
    end
  end

  def update
    @user = User.find(params[:id])
    if params[:avatar]
      @user.avatar.attach(params[:user][:avatar])
    end

    if @user.update(user_params)
      redirect_to user_path(current_user), notice: "ユーザ「#{@user.name}」を更新しました。"
    else
      render :new
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_url, notice: "ユーザ「#{@user.name}」を削除しました。"
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmaiton, :avatar)
  end

  def correct_user_check
    redirect_to root_path, alert: "権限がありません" unless @current_user.id == params[:id].to_i
  end
 
end