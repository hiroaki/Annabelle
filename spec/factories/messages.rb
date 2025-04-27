FactoryBot.define do
  factory :message do
    content { "Sample message content" }
    association :user
  end
end
