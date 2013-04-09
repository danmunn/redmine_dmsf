RedmineApp::Application.routes.draw do
  get "/projects/:id/dmsf", :controller => 'dmsf', :action => 'index'

  get "/projects/:id/dmsf/*dmsf_path", :controller => 'dmsf', :action => 'index'
  
  # Approval workflow  
  resources :dmsf_workflows  
end