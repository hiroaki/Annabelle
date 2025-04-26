class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :omniauthable, omniauth_providers: %i[github]

  has_many :messages

  # ユーザの削除時は、そのユーザのメッセージは残し、所有者を管理者にします。
  before_destroy :transfer_messages_to_admin

  # devise の database_authenticatable を使用するため email は必須です。
  # その他追加のフィールドについては、必要に応じてバリデーションを追加してください。
  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: /\A[a-zA-Z0-9_]+\z/, message: 'can only contain letters, numbers, and underscores' }

  # OAuth での登録時、初期ユーザ名はランダムな文字列にします。
  def self.generate_random_username
    10.times do
      username = "user_#{SecureRandom.alphanumeric(8).downcase}"
      return username unless User.exists?(username: username)
    end
    raise "Unable to generate unique username"
  end

  # OAuth での登録時、初期パスワードはランダムな文字列にします。
  def self.generate_random_password
    Devise.friendly_token[0, 20]
  end

  # OAuth コールバックを処理します。認証結果の auth に基づいてユーザーを返します。
  # 存在しないユーザの場合は作成して返します。
  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    if user.new_record?
      if auth.info.email.present?
        existing_user = User.find_by(email: auth.info.email)
        unless existing_user&.confirmed?
          existing_user.destroy
        end

        user.email = auth.info.email
        user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
      end

      user.username = generate_random_username
      user.password = generate_random_password

      if user.save
        logger.info("User created: #{user.id}")
      else
        logger.error("User creation failed: #{user.errors.full_messages.join(', ')}")
      end
    end

    user
  end

  def admin_user
    User.find_by(email: 'admin@localhost', admin: true)
  end

  private

  def transfer_messages_to_admin
    admin = admin_user
    if admin
      messages.update_all(user_id: admin.id)
    else
      logger.warn("Admin user not found. Cannot transfer messages for user_id: #{messages.first&.user_id}.")
    end
  end
end
