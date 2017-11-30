require 'mechanize'
require 'pry-rails'

class UsersParserService
  def initialize(url)
    @url = url.sub(/(\/)+$/,'')
  end

  def start
    agent = Mechanize.new
    agent.get(@url)
    page = agent.page.link_with(text: 'Sign in').click

    form = page.forms.first
    form['user[email]']    = Rails.application.secrets.user_email
    form['user[password]'] = Rails.application.secrets.user_password
    page = form.submit.link_with(text: 'Users').click

    page.parser.css('table tbody tr').each do |n|
      username     = n.css('td:first-child').text
      profile_url  = "#{@url}#{n.css("td:nth-child(4) a").attr('href').text}"
      avatar_image = n.css("td:nth-child(2) img").attr('src').text
      avatar_image_url = "#{@url}#{avatar_image}" if avatar_image.present?

      begin
        forum_user = ForumUser.find_or_create_by(username: username)
        forum_user.profile_url  = profile_url
        forum_user.remote_avatar_image_url = avatar_image_url if avatar_image.present?
        forum_user.save!
      rescue
        next
      end
    end
  end
end
