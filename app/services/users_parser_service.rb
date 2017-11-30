require 'mechanize'
require 'pry-rails'
require 'net/http'

class UsersParserService
  TITLE_STRUCTURE_OF_TABLE = {
    0 => 'username',
    1 => 'avatar',
    3 => 'actions'
  }.freeze

  def initialize(url)
    @url = url.sub(/(\/)+$/, '') # Get url without a slash
  end

  def call
    check_url
    data_scraping
  end

  private

  def check_url
    url_with_trailing_slash = @url + '/'

    url = URI.parse(url_with_trailing_slash)
    req = Net::HTTP.new(url.host, url.port)
    req.use_ssl = (url.scheme == 'https') # If url with https protocol
    res = req.request_head(url.path)

    raise 'Url is not valid' unless res.code == '200'
  end

  def go_to_users_page
    agent = Mechanize.new
    agent.get(@url)

    page = agent.page.link_with(text: 'Sign in').click

    form = page.forms.first
    form['user[email]']    = Rails.application.secrets.user_email
    form['user[password]'] = Rails.application.secrets.user_password
    form.submit.link_with(text: 'Users').click
  rescue => error
    puts "Go to users page: #{error}"
  end

  def data_scraping
    page = go_to_users_page
    tbody_structure = page.parser.css('table tbody tr')

    data_scraping_validations(page, tbody_structure)

    tbody_structure.each do |n|
      username         = n.css('td:first-child').text
      profile_url      = "#{@url}#{n.css('td:nth-child(4) a').attr('href').text}"
      avatar_image     = n.css('td:nth-child(2) img').attr('src').text
      avatar_image_url = "#{@url}#{avatar_image}" if avatar_image.present?

      # If forum_user is invalid then skip current forum_user and continue execution
      begin
        forum_user = ForumUser.find_or_create_by(username: username)
        forum_user.profile_url = profile_url
        forum_user.save!
      rescue
        next
      end

      # Update without validates, if avatar does't exist and user is correctly saved
      forum_user.update(remote_avatar_image_url: avatar_image_url) if avatar_image.present?
    end
  end

  def data_scraping_validations(page, tbody_structure)
    thead_structure = page.parser.css('table thead tr')

    raise 'Users page: table structure of thead is incorrect' if thead_structure.blank?
    raise 'Users page: table structure of tbody is incorrect' if tbody_structure.blank?

    thead_structure.css('th').each_with_index do |value, index|
      title_of_table = TITLE_STRUCTURE_OF_TABLE[index]

      if title_of_table.present?
        value = value.text.downcase

        unless title_of_table == value
          raise "Position or name of #{value} are incorrect"
        end
      end
    end
  end
end
