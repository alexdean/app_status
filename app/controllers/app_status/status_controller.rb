module AppStatus
  class StatusController < ::ApplicationController
    def index
      @checks = CheckCollection.new
      @checks.evaluate!

      json_data = @checks.as_json(include_descriptions: params[:descriptions])

      more_info_url = app_status_engine.root_url(descriptions: true)
      json_data['more_info'] = more_info_url

      render json: json_data
    end
  end
end
