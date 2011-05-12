ActionController::Routing::Routes.draw do |map|
  map.resource :dmsf, :member => {:sync => :put} do |dmsf|
    dmsf.resource :dmsf_detail, :as => 'detail'
    dmsf.resource :dmsf_state, :as => 'state'
  end
end
