module AppStatus
  class StatusController < ApplicationController
    def index
      @checks = CheckCollection.new
      @checks.evaluate!

      json_data = @checks.as_json
      json_data['more_info'] = app_status_url

      respond_to do |format|
        format.json { render json: json_data}
        format.html
      end
    end
  end
end
