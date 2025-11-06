# spec/support/omniauth_macros.rb
module OmniauthMacros
  def mock_github_auth(uid: "new_uid", email: "user@example.com", nickname: "githubuser")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: uid,
      info: {
        email: email,
        nickname: nickname
      }
    )
  end

  def clear_omniauth_mock
    OmniAuth.config.mock_auth[:github] = nil
  end
end
