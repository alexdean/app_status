Rails.application.routes.draw do
  resources :widgets

  mount AppStatus::Engine => "/status(.:format)", defaults: {format: 'json'}
end
