require 'spec_helper'

describe AppStatus::StatusController do

  describe "GET index" do
    before(:each) do
      AppStatus::CheckCollection.configure do |c|
        c.add(name: 'test', status: :ok, details: 'foo')
      end
    end

    it "should render json" do
      get :index, format: 'json', use_route: :app_status
      response.should be_success
      #puts response.inspect
    end

    it "should render html" do
      get :index, format: 'html', use_route: :app_status
      response.should be_success
      #puts response.inspect
    end
  end
end