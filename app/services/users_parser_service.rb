require 'mechanize'
require 'pry-rails'
require 'net/http'

class UsersParserService
  def initialize(url)
    @url = url.sub(/(\/)+$/, '') # Get url without a slash
  end

  def call
    check_url
    data_scraping
  end

  private

  def check_url
    url_with_trailing_slash = "#{@url}/"

    url = URI.parse(url_with_trailing_slash)
    req = Net::HTTP.new(url.host, url.port)
    req.use_ssl = (url.scheme == 'https') # If url with https protocol
    res = req.request_head(url.path)

    raise 'Url is not valid' unless res.code == '200'
  end

  def transition_to_users_page
    agent = Mechanize.new
    agent.get(@url)

    agent.page.link_with(text: 'Пользователи').click
  rescue => error
    raise "Transition with home page to page of users with next error: #{error}"
  end

  def data_scraping
    page = transition_to_users_page
    count_of_pages = page.css('.ipsList_inline .pagejump.clickable a').text.scan(/\d+/)[1]

    data_scraping_validations(page)

    for i in 1..count_of_pages.to_i
      page.css('ul.ipsMemberList > li').each do |element|
        username     = element.css('.ipsType_subtitle a').text
        profile_url  = element.css('.ipsType_subtitle a').attr('href').text
        avatar_image = element.css('.ipsUserPhotoLink img').attr('src').text

        # If forum_user is invalid then skip current forum_user and continue execution
        begin
          forum_user = ForumUser.find_or_create_by(username: username)
          forum_user.profile_url = profile_url
          forum_user.save!
        rescue
          next
        end

        # Update without validates, if avatar does't exist and user is correctly saved
        forum_user.update(remote_avatar_image_url: avatar_image) if avatar_image.present?
      end

      page = next_page(page)
    end
  end

  def next_page(page)
    next_element = page.css('.ipsList_inline li.page.active').first.next_element
    next_element = next_element.at_css('a')['href']

    page.link_with(href: next_element).click
  end

  def data_scraping_validations(page)
    list_structure    = page.css('ul.ipsMemberList li')
    current_page_link = page.css('.ipsList_inline li.page.active')
    count_of_pages    = page.css('.ipsList_inline .pagejump.clickable a')
    user_photo        = page.css('.ipsUserPhotoLink img')
    block_title       = page.css('.ipsType_subtitle a')

    raise 'Users page: structure of list is incorrect'                   if list_structure.blank?
    raise 'Users page: link to the current page is incorrect'            if current_page_link.blank?
    raise 'Users page: count of pages is incorrect'                      if count_of_pages.blank?
    raise 'Users page: structure of user photo is incorrect'             if user_photo.blank?
    raise 'Users page: block with username or profile_url are incorrect' if block_title.blank?
  end
end
