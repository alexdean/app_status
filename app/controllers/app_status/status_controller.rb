module AppStatus
  class StatusController < ::ApplicationController
    def index
      @checks = CheckCollection.new
      @checks.evaluate!

      json_data = @checks.as_json

      more_info = app_status_engine.root_url
      # try to build html url, when main app has route like '/status(.:format)'
      if match = more_info.match(/(.*)\.json/)
        more_info = match[1]+'.html'
      end
      json_data['more_info'] = more_info

      respond_to do |format|
        format.json { render json: json_data}
        format.html
      end
    end
  end
end
