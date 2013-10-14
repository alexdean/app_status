AppStatus::Engine.routes.draw do
  get '/index(.:format)', to: 'app_status/status#index'
  root to: 'app_status/status#index'
end
