require 'rails_helper'
require 'cgi'

RSpec.describe "Messages", type: :request do
  let(:confirmed_user) { create(:user, confirmed_at: Time.current) }
  let(:unconfirmed_user) { create(:user, confirmed_at: nil) }
  let!(:message) { create(:message, user: confirmed_user) }
  let(:other_user) { create(:user, :confirmed) }

  describe "POST /messages" do
    context "when user is confirmed" do
      before { sign_in confirmed_user }

      it "allows message creation" do
        post messages_path, params: { content: "Hello" }
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context "when user is unconfirmed" do
      context "Devise.allow_unconfirmed_access_for 7 days" do
        before do
          @original_value = Devise.allow_unconfirmed_access_for
          Devise.allow_unconfirmed_access_for = 7.days
          sign_in unconfirmed_user
        end

        after do
          Devise.allow_unconfirmed_access_for = @original_value
        end

        it "rejects message creation with 403" do
          post messages_path, params: { content: "Hi" }
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to include("Email confirmation required")
        end
      end

      context "Devise.allow_unconfirmed_access_for 0 days" do
        before do
          @original_value = Devise.allow_unconfirmed_access_for
          Devise.allow_unconfirmed_access_for = 0.days
          sign_in unconfirmed_user
        end

        after do
          Devise.allow_unconfirmed_access_for = @original_value
        end

        it "rejects message creation with 302" do
          post messages_path, params: { content: "Hi" }
          expect(response).to have_http_status(:found)
          expect(response.location).to eq 'http://www.example.com/en/users/sign_in'
        end
      end
    end
  end

  describe "DELETE /messages/:id" do
    context "when user is confirmed" do
      before { sign_in confirmed_user }

      it "allows message deletion" do
        delete message_path(message)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context "when user is unconfirmed" do
      context "Devise.allow_unconfirmed_access_for 7 days" do
        before do
          @original_value = Devise.allow_unconfirmed_access_for
          Devise.allow_unconfirmed_access_for = 7.days
          sign_in unconfirmed_user
        end

        after do
          Devise.allow_unconfirmed_access_for = @original_value
        end

        it "rejects message deletion with 403" do
          delete message_path(message)
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to include("Email confirmation required")
        end
      end

      context "Devise.allow_unconfirmed_access_for 0 days" do
        before do
          @original_value = Devise.allow_unconfirmed_access_for
          Devise.allow_unconfirmed_access_for = 0.days
          sign_in unconfirmed_user
        end

        after do
          Devise.allow_unconfirmed_access_for = @original_value
        end

        it "rejects message deletion with 302" do
          delete message_path(message)
          expect(response).to have_http_status(:found)
          expect(response.location).to eq 'http://www.example.com/en/users/sign_in'
        end
      end
    end

    context "when trying to delete another user's message" do
      before { sign_in other_user }

      it "does not allow deleting another user's message (HTML)" do
        delete message_path(message)
        expect(response.body).to include(CGI.escapeHTML(I18n.t('messages.errors.not_owned')))
        expect(Message.exists?(message.id)).to be true
      end
    end

    context "when trying to delete another user's message via Turbo Stream" do
      before { sign_in other_user }

      it "does not allow deleting another user's message and returns flash via turbo_stream" do
        delete message_path(message), as: :turbo_stream
        expect(response.media_type).to eq 'text/vnd.turbo-stream.html'
        expect(response.body).to include(CGI.escapeHTML(I18n.t('messages.errors.not_owned')))
        expect(Message.exists?(message.id)).to be true
      end
    end
  end
end
