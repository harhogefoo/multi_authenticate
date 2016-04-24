class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :destroy, :finish_signup]
  before_action :authenticate_user!, except: :finish_signup


  # OAuth認証による新規登録の〆を司るアクション
  # ユーザーデータを更新に成功したら，email確認メールを送付する
  # GET   /users/:id/finish_signup - 必要データの入力を求める
  # PATCH /users/:id/finish_signup -ユーザデータを更新
  def finish_signup
    if request.patch? && @user.update(user_params)
      @user.send_confirmation_instructions unless @user.confirmed?
      flash[:info] = 'We sent you a confirmation email. Please find a confirmation link.'
      redirect_to root_url
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # user_paramsにアクセスするため
  def user_params
    accessible = [ :username, :email ]
    accessible << [ :password, :password_confirmation ] unless params[:user][:password].blank?
    params.require(:user).permit(accessible)
  end

end
