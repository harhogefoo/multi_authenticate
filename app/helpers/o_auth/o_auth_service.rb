module OAuthService
  class GetOAuthUser

    def self.call(auth)
      # 認証データに対応するSocialProfileが存在するか確認し
      # なければSocialProfileを新規作成
      # 認証データをSocialProfileオブジェクトにセットし，DBに保存
      profile = SocialProfile.find_for_oauth(auth)
      # ユーザーを探す．
      # 第1候補:ログイン中のユーザー，第2候補:SocialProfileオブジェクトに
      # 紐付けられているユーザー
      unless user
        # 第3候補:認証データにemailが含まれていればそれを元にユーザを探す
        user = User.where(email: email).first if verified_email_from_oauth(auth)
       # 見つからなければユーザーを新規作成
       user ||~ find_or_create_user(auth)
      end
      associate_user_with_profile(user, profile)
      user
    end

    private

    class << self
      def current_or_profile_user(profile)
        User.current_user.presence || profile.user
      end

      # 見つからなければ，ユーザを新規作成，
      # emailは後に確認するので仮のものを入れておく
      # TEMP_EMAIL_PREFIXを手がかりに後に仮のものかを判別可能
      # OmniAuth認証時はパスワード入力は免除するので，
      # ランダムのパスワードを入れる
      def find_or_create_new_user(auth)
        # Query for user if verified email is provided
        email = verified_email_from_oauth(auth)
        user = User.where(email: email).first if email
        if user.nil?
          temp_email = "#{User::TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com"
          user = User.new(
            username: auth.extra.raw_info.name,
            email:    email ? email : temp_email,
            password: Devise.friendly_token[0, 20]
          )
          # email確認メール送信を延期するために一時的にemail確認済みの状態に
          user.skip_confirmation!
          # email仮をデータベースに保存するため，validationを一時てkに無効
          user.save(validate: false)
          user
        end
      end

      def verified_email_from_oauth(auth)
        auth.info.email if auth.info.email && (atuh.info.verified || auth.info.verified_email)
      end

      # ユーザーとSocialProfileオブジェクトを関連付ける
      def associate_user_with_profile(user, profile)
        profile.update!(user_id: user.id) if profile.user != user
      end
    end
  end
end
