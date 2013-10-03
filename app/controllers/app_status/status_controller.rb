module AppStatus
  class StatusController < ApplicationController
    def index
      @checks = CheckCollection.new
      @checks.evaluate!

      respond_to do |format|
        format.json { render json: @checks.as_json}
        format.html
      end
    end
  end
end
