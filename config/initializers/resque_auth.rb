Resque::Server.use(Rack::Auth::Basic) do |user, password|
  user     == Rails.application.secrets.resque_admin_user
  password == Rails.application.secrets.resque_admin_password
end
