class DmsfWorkflowsController < ApplicationController
  unloadable
  layout 'admin'
    
  before_filter :require_admin
  before_filter :find_workflow, :except => [:create, :new, :index]

  def index    
    @workflow_pages, @workflows = paginate Dmsf::Workflow, :per_page => 25
  end

  def action
  end

  def log
  end
  
  def new   
    @workflow = Dmsf::Workflow.new
  end
  
  def create
    @workflow = Dmsf::Workflow.new({:name => params[:dmsf_workflow][:name]})
    if request.post? && @workflow.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to dmsf_workflows_path
    else
      render_validation_errors(@workflow)
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
      render_validation_errors(@workflow)
      render :action => 'edit'
    end
  end
  
  def destroy    
    begin
      @workflow.destroy    
    rescue
      flash[:error] = l(:error_unable_delete_dmsf_workflow)
    end
    redirect_to dmsf_workflows_path
  end
  
  def autocomplete_for_user
    respond_to do |format|      
      format.js
    end        
  end
  
  def add_step     
    if request.post?      
      users = User.find_all_by_id(params[:user_ids])      
      if params[:step] == '0'
        if @workflow.steps.count > 0
          step = @workflow.steps.last + 1
        else
          step = 1
        end
      else
        step = params[:step].to_i
      end
      operator = 1 ? params[:commit] == l(:dmsf_and) : 0      
      users.each do |user|
        @workflow.workflow_steps << Dmsf::WorkflowStep.new(
          :workflow_id => @workflow.id, 
          :step => step, 
          :user_id => user.id, 
          :operator => operator)
      end   
      @workflow.save      
    end             
    respond_to do |format|
      format.html            
    end        
  end
  
  def remove_step        
    if request.delete? && params[:step_no].present?
      Dmsf::WorkflowStep.where(['workflow_id = ? AND step = ?', @workflow.id, params[:step_no]]).each do |ws|
        @workflow.workflow_steps.delete(ws)
      end              
      @workflow.workflow_steps.each do |ws|
        n = ws.step.to_i
        if n > params[:step_no].to_i        
          ws.step = n - 1
          ws.save
        end
      end
    end        
    respond_to do |format|
      format.html      
    end
  end
  
  private    
  
  def find_workflow   
    @workflow = Dmsf::Workflow.find(params[:id])
  end
end
