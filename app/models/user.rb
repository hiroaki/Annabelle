class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :two_factor_authenticatable, :two_factor_backupable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :omniauthable, omniauth_providers: Devise.omniauth_configs.keys

  # for two_factor_backupable
  attribute :otp_backup_codes, JsonStringArrayType.new, default: []

  has_many :authorizations, dependent: :destroy
  has_many :messages

  # ユーザの削除時は、そのユーザのメッセージは残し、所有者を管理者にします。
  before_destroy :transfer_messages_to_admin!

  # devise の database_authenticatable を使用するため email は必須です。
  # その他追加のフィールドについては、必要に応じてバリデーションを追加してください。
  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: /\A[a-zA-Z0-9_]+\z/, message: :invalid_format },
    length: { minimum: 3, maximum: 255 }

  # カスタムバリデータ LocaleValidator が用意されてあります。
  validates :preferred_language, locale: true

  # 管理者ユーザを返します。（これは db:seed で追加されている特別なレコードです）
  # TODO: 変更不可にする
  def self.admin_user
    User.find_by(email: 'admin@localhost', admin: true)
  end

  # OAuth での登録時、初期ユーザ名はランダムな文字列にします。
  def self.generate_random_username!
    10.times do
      username = "user_#{SecureRandom.alphanumeric(8).downcase}"
      return username unless User.exists?(username: username)
    end
    raise 'Unable to generate unique username'
  end

  # OAuth での登録時、初期パスワードはランダムな文字列にします。
  def self.generate_random_password
    Devise.friendly_token[0, 20]
  end

  # OAuth コールバックを処理します。認証結果の auth に基づいてユーザーを返します。
  # 存在しないユーザの場合は作成して返します。
  def self.from_omniauth(auth)
    user = nil

    begin
      transaction do
        authorization = Authorization.find_by(provider: auth.provider, uid: auth.uid)
        return authorization.user if authorization

        if auth.info.email.present?
          existing_user = find_by(email: auth.info.email)

          if existing_user&.confirmed?
            user = existing_user
          elsif existing_user
            existing_user.destroy
          end
        end

        unless user
          user = new(
            email: auth.info.email,
            username: generate_random_username!,
            password: generate_random_password
          )
          user.skip_confirmation! if user.respond_to?(:skip_confirmation!)

          unless user.save
            Rails.logger.error("User creation failed: #{user.errors.full_messages.join(', ')}")
            raise ActiveRecord::Rollback
          end
        end

        auth_record = user.authorizations.build(provider: auth.provider, uid: auth.uid)

        unless auth_record.save
          Rails.logger.error("Authorization creation failed for user (#{user.id}): #{auth_record.errors.full_messages.join(', ')}")
          raise ActiveRecord::Rollback
        end
      end
    rescue => e
      Rails.logger.error("from_omniauth: #{e}")
    end

    user
  end

  # 指定したプロバイダとUIDで連携を追加します。
  def link_with(provider, uid)
    authorizations.find_or_create_by(provider: provider, uid: uid)
  end

  # 指定した provider に紐づく認証情報が存在すれば true を返します。
  def linked_with?(provider)
    authorizations.exists?(provider: provider.to_s)
  end

  # 指定した provider のレコードを返します。
  def authorization_by_provider(provider)
    authorizations.find_by(provider: provider.to_s)
  end

  # 指定した provider の uid を返します。
  def provider_uid(provider)
    authorization_by_provider(provider)&.uid
  end

  # Generate an OTP secret it it does not already exist
  def generate_two_factor_secret_if_missing!
    return unless otp_secret.nil?
    update!(otp_secret: User.generate_otp_secret)
  end

  # Ensure that the user is prompted for their OTP when they login
  def enable_two_factor!
    update!(otp_required_for_login: true)
  end

  # Disable the use of OTP-based two-factor.
  def disable_two_factor!
    update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_codes: nil,
    )
  end

  # Determine if backup codes have been generated
  def two_factor_backup_codes_generated?
    otp_backup_codes.present?
  end

  def two_factor_qr_code_uri
    issuer = 'Annabelle' # TODO --> ENV['OTP_2FA_ISSUER_NAME']
    label = [issuer, email].join(':')

    otp_provisioning_uri(label, issuer: issuer)
  end

  private

  def transfer_messages_to_admin!
    admin = self.class.admin_user

    if admin
      messages.update_all(user_id: admin.id)
    else
      raise "Admin user not found. Cannot transfer messages for user_id: #{id}."
    end
  end
end
