require 'spec_helper'

RSpec::Matchers.define :have_content_type do |expected|

  def extract_content_type(actual)
    actual.response_headers['Content-Type'].split(';')[0]
  end

  match do |actual|
    extract_content_type(actual) == expected
  end

  failure_message_for_should do |actual|
    "expected that page's content type would be '#{expected}', but was '#{extract_content_type(actual)}'"
  end

end

describe "status" do

  before(:each) do
    AppStatus::CheckCollection.clear_checks!
    AppStatus::CheckCollection.configure do |c|
      c.add_check('some_service') {[:ok, 'foo']}
      c.add_description('some_service', "more info")
    end
  end

  it "renders json by default" do
    visit "/status"
    page.should have_content_type('application/json')
  end

  describe "json endpoint" do

    it "is available at status.json" do
      visit '/status.json'
      page.should have_content_type('application/json')
    end

    it "is available at /status/index.json" do
      visit '/status/index.json'
      page.should have_content_type('application/json')
    end

    it "links to html status page" do
      visit '/status.json'
      page.should have_content_type('application/json')
      data = JSON.parse(page.body)

      data['more_info'].should eq 'http://www.example.com/status.html'
    end

    it "contains status information" do
      visit '/status.json'
      page.should have_content_type('application/json')
      data = JSON.parse(page.body)

      data['status'].should eq 'ok'
      data['status_code'].should eq 0
      data['checks']['some_service']['status'].should eq 'ok'
      data['checks']['some_service']['details'].should eq 'foo'
    end

  end
end
