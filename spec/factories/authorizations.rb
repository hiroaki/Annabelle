# spec/factories/authorizations.rb
FactoryBot.define do
  factory :authorization do
    association :user
    provider { "github" }
    uid { SecureRandom.uuid }
  end
end

