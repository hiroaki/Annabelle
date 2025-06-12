require 'rails_helper'
require 'ostruct'

RSpec.describe User, type: :model do
  describe "バリデーション" do
    describe "username" do
      subject { build(:user) }

      context "存在性" do
        it "必須であること" do
          is_expected.to validate_presence_of(:username)
        end
      end

      context "一意性（大文字小文字を区別しない）" do
        it "一意であること" do
          is_expected.to validate_uniqueness_of(:username).case_insensitive
        end
      end

      context "フォーマット" do
        it "有効な形式を許可すること" do
          is_expected.to allow_value("valid_username_123").for(:username)
        end

        it "無効な形式を拒否すること" do
          is_expected.not_to allow_value("invalid username!").for(:username)
        end
      end
    end

    describe "インスタンスの検証" do
      it "有効なユーザーを作成できること" do
        user = build(:user, username: "valid_user", email: "user@example.com")
        expect(user).to be_valid
      end

      it "username が空だと無効になること" do
        user = build(:user, username: nil)
        expect(user).to be_invalid
        expect(user.errors[:username]).to include(I18n.t("errors.messages.blank"))
      end

      it "username が重複すると無効になること" do
        create(:user, username: "duplicate_user")
        user = build(:user, username: "duplicate_user")
        expect(user).to be_invalid
        expect(user.errors[:username]).to include(I18n.t("errors.messages.taken"))
      end

      it "username が無効な形式だと無効になること" do
        user = build(:user, username: "invalid user!")
        expect(user).to be_invalid
        expect(user.errors[:username]).to include(I18n.t("errors.messages.invalid_format"))
      end

      it "username が255文字まで有効であること" do
        user = build(:user, username: 'a' * 255)
        expect(user).to be_valid
      end

      it "username が256文字だと無効になること" do
        user = build(:user, username: 'a' * 256)
        expect(user).to be_invalid
      end

      it "username が3文字未満だと無効になること" do
        user = build(:user, username: 'ab')
        expect(user).to be_invalid
        expect(user.errors[:username]).to include(I18n.t("errors.messages.too_short", count: 3))
      end

      it "username が3文字は有効であること" do
        user = build(:user, username: 'abc')
        expect(user).to be_valid
      end

      it "emailがnilの場合は無効になること" do
        user = build(:user, email: nil)
        expect(user).to be_invalid
      end

      it "emailが空文字の場合は無効になること" do
        user = build(:user, email: '')
        expect(user).to be_invalid
      end

      it "不正な形式のemailは無効になること" do
        user = build(:user, email: 'invalid-email')
        expect(user).to be_invalid
      end
    end
  end

  describe ".generate_random_username!" do
    context "ユニークな username が生成できる場合" do
      it "正規表現に一致する username を返すこと" do
        username = described_class.generate_random_username!
        expect(username).to match(/\Auser_[a-z0-9]{8}\z/)
      end
    end

    context "10 回の試行でも重複する場合" do
      before do
        allow(SecureRandom).to receive(:alphanumeric).and_return("duplicate")
        create(:user, username: "user_duplicate")
      end

      it "エラーが発生すること" do
        expect {
          described_class.generate_random_username!
        }.to raise_error("Unable to generate unique username")
      end
    end
  end

  describe ".generate_random_password" do
    it "20 文字のパスワードを返すこと" do
      password = described_class.generate_random_password
      expect(password.length).to eq(20)
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "github",
        uid: "12345",
        info: OpenStruct.new(email: "user@example.com", nickname: "githubuser")
      )
    end

    context "該当する Authorization が存在する場合" do
      let!(:user_with_auth) { create(:user) }
      let!(:authorization) { create(:authorization, user: user_with_auth, provider: "github", uid: "12345") }

      it "そのユーザーを返すこと" do
        expect(described_class.from_omniauth(auth)).to eq(user_with_auth)
      end
    end

    context "既存ユーザーがいない場合" do
      it "確認済みユーザーと Authorization が作成されること" do
        expect {
          @user = described_class.from_omniauth(auth)
        }.to change(User, :count).by(1)

        expect(@user).to be_persisted
        expect(@user.email).to eq("user@example.com")
        expect(@user.username).to match(/\Auser_[a-z0-9]{8}\z/)
        expect(@user.confirmed?).to be true
        expect(@user.authorizations).to exist(provider: "github", uid: "12345")
      end
    end

    context "未確認の既存ユーザーがいる場合" do
      let!(:unconfirmed_user) { create(:user, email: "user@example.com", confirmed_at: nil) }

      it "未確認ユーザーは削除され、新たなユーザーが作成されること" do
        expect {
          described_class.from_omniauth(auth)
        }.not_to change(User, :count)

        user = User.find_by(email: "user@example.com")
        expect(user.authorizations).to exist(provider: "github", uid: "12345")
      end
    end

    context "確認済みの既存ユーザーがいる場合" do
      let!(:confirmed_user) { create(:user, email: "user@example.com", confirmed_at: Time.current) }

      it "Authorization が追加されること" do
        expect {
          described_class.from_omniauth(auth)
        }.to change(Authorization, :count).by(1)

        user = User.find_by(email: "user@example.com")
        expect(user).to eq(confirmed_user)
        expect(user.authorizations).to exist(provider: "github", uid: "12345")
      end
    end

    context "auth 情報に email がない場合" do
      let(:auth_without_email) do
        OmniAuth::AuthHash.new(provider: "github", uid: "12345", info: OpenStruct.new(nickname: "githubuser"))
      end

      it "ユーザーは作成されないこと" do
        expect {
          user = described_class.from_omniauth(auth_without_email)
          expect(user).not_to be_persisted
        }.not_to change(User, :count)
      end
    end

    context "Authorization の保存に失敗する場合" do
      before do
        allow_any_instance_of(Authorization).to receive(:save).and_return(false)
      end

      it "ユーザーは保存されないこと" do
        expect {
          user = described_class.from_omniauth(auth)
          expect(user).not_to be_persisted
        }.not_to change(User, :count)
      end
    end
  end

  describe "#transfer_messages_to_admin!" do
    let!(:admin) { User.admin_user }
    let!(:user) { create(:user) }
    let!(:messages) { create_list(:message, 3, user: user) }

    context "管理者ユーザーが存在する場合" do
      it "メッセージが管理者に移管されること" do
        expect {
          user.destroy
        }.to change { messages.map(&:reload).map(&:user_id).uniq }.to([admin.id])
      end
    end

    context "管理者ユーザーが存在しない場合" do
      before { admin.destroy }

      it "例外が発生すること" do
        expect {
          user.destroy
        }.to raise_error(RuntimeError, /Admin user not found/)
      end
    end
  end

  describe ".admin_user" do
    context "admin ユーザーが存在する場合" do
      it "admin ユーザーを返すこと" do
        admin = User.admin_user
        expect(admin).to be_present
        expect(admin.email).to eq('admin@localhost')
        expect(admin.admin).to be true
      end
    end

    context "admin ユーザーが存在しない場合" do
      it "nil を返すこと" do
        admin = User.admin_user
        admin.destroy
        expect(User.admin_user).to be_nil
      end
    end
  end

  describe "#link_with" do
    let(:user) { create(:user) }

    it "Authorization を作成すること" do
      user.link_with('github', '12345')
      expect(user.authorizations).to exist(provider: 'github', uid: '12345')
    end
  end

  describe "#linked_with?" do
    let(:user) { create(:user) }

    context "provider に対応する Authorization がある場合" do
      before { user.link_with('github', '12345') }

      it "true を返すこと" do
        expect(user.linked_with?('github')).to be true
      end
    end

    context "provider に対応する Authorization がない場合" do
      it "false を返すこと" do
        expect(user.linked_with?('google')).to be false
      end
    end
  end

  describe "#authorization_by_provider" do
    let(:user) { create(:user) }
    let!(:auth) { create(:authorization, user: user, provider: "github", uid: "12345") }

    context "存在する provider を指定した場合" do
      it "対応する Authorization を返すこと" do
        expect(user.authorization_by_provider("github")).to eq(auth)
      end
    end

    context "存在しない provider を指定した場合" do
      it "nil を返すこと" do
        expect(user.authorization_by_provider("google")).to be_nil
      end
    end
  end

  describe "#provider_uid" do
    let(:user) { create(:user) }
    let!(:auth) { create(:authorization, user: user, provider: "github", uid: "abc123") }

    context "対応する Authorization がある場合" do
      it "uid を返すこと" do
        expect(user.provider_uid("github")).to eq("abc123")
      end
    end

    context "対応する Authorization がない場合" do
      it "nil を返すこと" do
        expect(user.provider_uid("google")).to be_nil
      end
    end
  end

  describe "#generate_two_factor_secret_if_missing!" do
    let(:user) { create(:user, otp_secret: otp_secret) }

    context "otp_secret が nil の場合" do
      let(:otp_secret) { nil }

      it "新しい otp_secret を生成して保存すること" do
        expect(user.otp_secret).to be_nil
        expect(User).to receive(:generate_otp_secret).and_call_original
        expect { user.generate_two_factor_secret_if_missing! }
          .to change { user.reload.otp_secret }.from(nil)
        expect(user.otp_secret).to be_present
      end
    end

    context "otp_secret が既に存在する場合" do
      let(:otp_secret) { "existingsecret" }

      it "otp_secret を変更しないこと" do
        expect { user.generate_two_factor_secret_if_missing! }
          .not_to change { user.reload.otp_secret }
      end
    end
  end

  describe "#enable_two_factor!" do
    let(:user) { create(:user, otp_required_for_login: false) }

    it "otp_required_for_login が true になること" do
      expect {
        user.enable_two_factor!
      }.to change { user.reload.otp_required_for_login }.from(false).to(true)
    end
  end

  describe "#disable_two_factor!" do
    let(:user) do
      create(:user,
        otp_required_for_login: true,
        otp_secret: "somesecret",
        otp_backup_codes: ["code1", "code2"]
      )
    end

    it "otp_required_for_login が false になること" do
      expect {
        user.disable_two_factor!
      }.to change { user.reload.otp_required_for_login }.from(true).to(false)
    end

    it "otp_secret が nil になること" do
      expect {
        user.disable_two_factor!
      }.to change { user.reload.otp_secret }.from("somesecret").to(nil)
    end

    it "otp_backup_codes が空配列になること" do
      expect {
        user.disable_two_factor!
      }.to change { user.reload.otp_backup_codes }.from(["code1", "code2"]).to([])
    end
  end

  describe "#two_factor_backup_codes_generated?" do
    let(:user) { create(:user, otp_backup_codes: backup_codes) }

    context "otp_backup_codes が存在する場合" do
      let(:backup_codes) { ["code1", "code2"] }

      it "true を返すこと" do
        expect(user.two_factor_backup_codes_generated?).to be true
      end
    end

    context "otp_backup_codes が nil の場合" do
      let(:backup_codes) { nil }

      it "false を返すこと" do
        expect(user.two_factor_backup_codes_generated?).to be false
      end
    end

    context "otp_backup_codes が空配列の場合" do
      let(:backup_codes) { [] }

      it "false を返すこと" do
        expect(user.two_factor_backup_codes_generated?).to be false
      end
    end
  end

  describe "#two_factor_qr_code_uri" do
    let(:user) { create(:user, email: "test@example.com", otp_secret: "SECRET") }

    it "issuer とメールアドレスを含む provisioning URI を返すこと" do
      uri = user.two_factor_qr_code_uri
      expect(uri).to be_a(String)
      expect(uri).to include("Annabelle")
      expect(uri).to include("test%40example.com")
      expect(uri).to include("otpauth://totp/")
    end
  end

  describe "preferred_language バリデーション（LocaleValidator統合テスト）" do
    subject { build(:user) }

    context '有効な値' do
      it '有効なロケール文字列を受け入れる' do
        subject.preferred_language = 'ja'
        expect(subject).to be_valid
      end

      it '空文字を受け入れる（デフォルト値）' do
        subject.preferred_language = ''
        expect(subject).to be_valid
      end
    end

    context '無効な値' do
      it '無効なロケールを拒否し、適切なエラーメッセージを表示する' do
        I18n.with_locale(:ja) do
          subject.preferred_language = 'invalid'
          expect(subject).not_to be_valid
          expect(subject.errors[:preferred_language]).to include('は有効なロケールではありません')
        end
      end

      it 'I18n.available_localesに含まれるロケールのみを受け入れる' do
        LocaleConfiguration.available_locales.each do |locale|
          user = build(:user, preferred_language: locale.to_s)
          expect(user).to be_valid, "#{locale} should be valid"
        end
      end
    end
  end
end
