class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # いくつプロバイダーを利用しようが処理は共通しているので本メソッドを
  # エイリアスとして流用
  def callback_for_all_providers
    unless env["omniauth.auth"].present?
      flash[:danger] = "Authentication data was not provided"
      redirect_to root_url and return
    end
    provider = __callee__.to_s
    user = OAuthService::GetOAuthUser.call(env["omniauth.auth"])
    # ユーザーがデータベースに保存されており，かつemailを確認済みであれば
    # ユーザログインをする
    if user.persisted? && user.email_verified?
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.capitalize) if is_navigational_format?
    else
      user.reset_confirmation!
      flash[:warning] = "We need your email address before proceeding."
      redirect_to finish_signup_path(user)
    end
  end
  alias_method :facebook, :callback_for_all_providers
  alias_method :twitter, :callback_for_all_providers
end
