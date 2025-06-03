FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "username#{n}" }
    password { "password123" }
    confirmed_at { Time.current }

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_github_oauth do
      after(:create) do |user|
        create(:authorization, user: user, provider: "github", uid: SecureRandom.uuid)
      end
    end

    trait :with_otp do
      otp_secret { User.generate_otp_secret } # assumes you use rotp or similar
      otp_required_for_login { true }
    end
  end
end
