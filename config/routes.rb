RedmineApp::Application.routes.draw do
  get "/projects/:id/dmsf", :controller => 'dmsf', :action => 'index'

  get "/projects/:id/dmsf/*dmsf_path", :controller => 'dmsf', :action => 'index'
  
  # Approval workflow
  get "/projects/:id/workflow", :to => 'workflow#index'
  get "workflow", :to => 'workflow#index'
  get "workflow/:id/show", :to => 'workflow#show'
  get "workflow/:id/log", :to => 'workflow#log'
  post "workflow/:id/action", :to => 'workflow#action'
  
  resource :workflow
  match "/projects/:id/workflow", :to => 'workflow#index', :via => :get, :as => 'workflow'
  match "/workflow", :to => 'workflow#index', :via => :get, :as => 'workflow'
  match '/workflow/:id', :to => 'workflow#show', :via => :get, :as => 'workflow'
  match '/workflow/:id', :to => 'workflow#destroy', :via => :delete, :as => 'workflow'
  match '/workflow/:id', :to => 'workflow#create', :via => :post, :as => 'workflow'
  match '/workflow/:id', :to => 'workflow#update', :via => :put, :as => 'workflow'
  match 'workflow/:id/log', :to => 'workflow#log', :via => :get, :as => 'workflow'
  match 'workflow/:id/action', :to => 'workflow#action', :via => :post, :as => 'workflow'
end