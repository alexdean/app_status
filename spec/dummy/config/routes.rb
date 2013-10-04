Rails.application.routes.draw do

  mount AppStatus::Engine => "/status"
end
