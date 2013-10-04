require 'spec_helper'

describe AppStatus::StatusController do

  describe "GET index" do
    before(:each) do
      AppStatus::CheckCollection.configure do |c|
        c.add(name: 'some_service', status: :ok, details: 'foo')
      end
    end

    it "should render json" do
      get :index, format: 'json', use_route: :app_status
      response.should be_success

      data = JSON.parse(response.body)
      data['status'].should eq 'ok'
      data['status_code'].should eq 0
      data['checks']['some_service']['status'].should eq 'ok'
      data['checks']['some_service']['details'].should eq 'foo'
    end

    it "should render html" do
      get :index, format: 'html', use_route: :app_status
      response.should be_success
      # FIXME: response.body == "". why?
    end
  end
end
