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
        expect(user.errors[:username]).to include(I18n.t("activerecord.errors.models.user.attributes.username.invalid_format"))
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
end
