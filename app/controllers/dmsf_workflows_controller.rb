class DmsfWorkflowsController < ApplicationController
  unloadable
  layout 'admin'
    
  before_filter :require_admin
  before_filter :find_workflow, :except => [:create, :new, :index]

  def index    
    @workflow_pages, @workflows = paginate DmsfWorkflow, :per_page => 25
  end

  def action
  end

  def log
  end
  
  def new   
    @workflow = DmsfWorkflow.new
  end
  
  def create
    @workflow = DmsfWorkflow.new({:name => params[:dmsf_workflow][:name]})
    if request.post? && @workflow.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to dmsf_workflows_path
    else
      render :action => 'new'
    end
  end
  
  def edit    
  end
  
  def update    
    if request.put? && @workflow.update_attributes({:name => params[:dmsf_workflow][:name]})
      flash[:notice] = l(:notice_successful_update)
      redirect_to dmsf_workflows_path
    else
      render :action => 'edit'
    end
  end
  
  def destroy    
    @workflow.destroy
    redirect_to dmsf_workflows_path
  rescue
    flash[:error] = l(:error_unable_delete_dmsf_workflow)
    redirect_to dmsf_workflows_path
  end
  
  private    
  
  def find_workflow
    @workflow = DmsfWorkflow.find(params[:id])
  end
end
