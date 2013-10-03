Rails.application.routes.draw do

  mount Healthcheck::Engine => "/healthcheck"
end
