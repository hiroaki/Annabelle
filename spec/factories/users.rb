FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    username { "user_#{SecureRandom.alphanumeric(8).downcase}" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current } # デフォルトで「確認済み」にしておく

    trait :admin do
      email { "admin@localhost" }
      admin { true }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :github_oauth do
      provider { "github" }
      uid { SecureRandom.uuid }
    end
  end
end
