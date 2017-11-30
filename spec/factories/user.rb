FactoryBot.define do
  factory :user do
    email    { FFaker::Internet.email }
    username { FFaker::Name.unique.name }
    password '111111'
  end
end
