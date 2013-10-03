AppStatus::Engine.routes.draw do
  root :to => 'status#index', :defaults => {:format => 'json'}
  match "/index" => 'status#index'
end
