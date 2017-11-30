class UsersScraping
  @queue = :default

  def self.perform
    url_for_scraping = Rails.application.secrets.url_for_scraping

    UsersParserService.new(url_for_scraping).call
  end
end
