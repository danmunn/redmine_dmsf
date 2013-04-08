require "#{Rails.root}/plugins/redmine_dmsf/app/models/dmsf/workflow.rb"

class WorkflowController < ApplicationController
  unloadable
  layout 'admin'
  
  before_filter :find_project
  before_filter :require_admin

  def index
    @workflows = Dmsf::DmsfWorkflow.workflows @project
  end

  def show
  end

  def action
  end

  def log
  end
  
  private
  
  def find_project
    @project = Project.find_by_id(params[:id])
  end
end
