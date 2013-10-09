AppStatus::Engine.routes.draw do
  root :to => 'status#index', :defaults => {:format => 'json'}
  get "/index" => 'status#index'
end
