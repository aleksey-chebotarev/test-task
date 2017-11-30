require 'ffaker'

User.create!(
  email: 'email@example.email',
  username: FFaker::Name.unique.name,
  avatar: File.new("#{Rails.root}/app/assets/images/avatars/avatar_#{rand(1..3)}.jpg"),
  password: '111111',
  password_confirmation: '111111'
)

10.times.each do
  user = User.create!(
    email: FFaker::Internet.email,
    username: FFaker::Name.unique.name,
    avatar: File.new("#{Rails.root}/app/assets/images/avatars/avatar_#{rand(1..3)}.jpg"),
    password: '111111',
    password_confirmation: '111111'
  )

  puts "User #{user.username} was created"
end
