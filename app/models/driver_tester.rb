class DriverTester < ActiveRecord::Base
  require 'selenium-webdriver'
  require 'date'

  def self.scrape(username, password, query)
    start = Time.now

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    driver = Selenium::WebDriver.for :chrome, options: options

    wait = Selenium::WebDriver::Wait.new(timeout: 10)

    driver.navigate.to 'https://acenet.aceservices.com/'

    begin
      driver.find_element(:id, 'tbxSearchBox')
    rescue StandardError
      driver.find_element(id: 'user_name').send_keys(username)
      driver.find_element(id: 'password').send_keys(password)
      driver.find_element(id: 'password').send_keys(:enter)

      p 'Logging in'
    end

    driver.find_element(:id, 'tbxSearchBox').send_keys(query)
    driver.find_element(:id, 'tbxSearchBox').send_keys(:enter)
    p 'Submitting query'

    iframe = driver.find_element(tag_name: 'iframe')
    driver.switch_to.frame(iframe)
    p 'Switched to IFrame'

    wait.until do
      driver.find_element(id: 'divSearchContentWrapper').displayed?
    end

    p 'Wrapper located'

    results = wait.until do
      elements = driver.find_elements(class_name: 'productResult')
      elements if elements.any?
    end

    p "#{results.size} Results found"

    quantities = []

    results.each_with_index do |result, index|
      begin
        data = result.find_element(id: qoh_id_from_index(index))
        next if data.nil? || (data.text.to_i < 1)
        qoh = data.text.to_i
      rescue Selenium::WebDriver::Error::NoSuchElementError
        next
      end

      data = result.find_element(id: sku_id_from_index(index))
      sku = data.nil? ? nil : data.text

      data = result.find_element(id: location_id_from_index(index))
      location = data.nil? ? nil : data.text

      data = result.find_element(id: description_id_from_index(index))
      description = data.nil? ? nil : data.text

      quantities << { description: description, sku: sku, qoh: qoh, location: location }
    end

    finish = Time.now
    total_time = finish - start
    p "Total Time for page load - #{total_time}"

    driver.quit

    quantities
  end

  private_class_method def self.sku_id_from_index(index)
    "ctl00_MainContentPlaceHolder_lvSearchResults_ctrl#{index}_hrefSKUvalue"
  end

  private_class_method def self.location_id_from_index(index)
    "ctl00_MainContentPlaceHolder_lvSearchResults_ctrl#{index}_lblStoreLocation"
  end

  private_class_method def self.qoh_id_from_index(index)
    "ctl00_MainContentPlaceHolder_lvSearchResults_ctrl#{index}_lblStoreQOH"
  end

  private_class_method def self.description_id_from_index(index)
    "ctl00_MainContentPlaceHolder_lvSearchResults_ctrl#{index}_lblExpandedDescription"
  end
end
