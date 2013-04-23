RedmineApp::Application.routes.draw do
  get "/projects/:id/dmsf", :controller => 'dmsf', :action => 'index'
  get "/projects/:id/dmsf/*dmsf_path", :controller => 'dmsf', :action => 'index', :as => 'dmsf_index', :format => false
  
  # Approval workflow    
  resources :dmsf_workflows do
    member do
      get 'autocomplete_for_user'
    end
  end
  
  match 'dmsf_workflows/:id/edit', :controller => 'dmsf_workflows', :action => 'add_step', :id => /\d+/, :via => :post
  match 'dmsf_workflows/:id/edit', :controller => 'dmsf_workflows', :action => 'remove_step', :id => /\d+/, :via => :delete
end