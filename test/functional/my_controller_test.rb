# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class MyControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n
    
  fixtures :users, :email_addresses, :user_preferences, :projects, :dmsf_workflows, :dmsf_workflow_steps,
           :dmsf_workflow_step_assignments, :dmsf_workflow_step_actions, :dmsf_file_revisions, :dmsf_folders,
           :dmsf_files, :dmsf_locks

  def setup
    @user_member = User.find 2
    User.current = nil
    @request.session[:user_id] = @user_member.id    
  end 
  
  def test_truth    
    assert_kind_of User, @user_member    
  end
  
  def test_page_with_open_approvals_block
    ### Postgres test
    all_assignments = DmsfWorkflowStepAssignment.joins(
      'LEFT JOIN dmsf_workflow_step_actions ON dmsf_workflow_step_assignments.id = dmsf_workflow_step_actions.dmsf_workflow_step_assignment_id').where(
      :dmsf_workflow_step_assignments => { :user_id => @user_member.id }).where(
      ['dmsf_workflow_step_actions.id IS NULL OR dmsf_workflow_step_actions.action = ?', DmsfWorkflowStepAction::ACTION_DELEGATE])
    puts all_assignments.to_sql
    puts "all assignments count: #{all_assignments.all.size}"
    assignments = []
    all_assignments.find_each do |assignment|
      puts assignment.id
      puts assignment.dmsf_file_revision.dmsf_file.last_revision.present?
      puts assignment.dmsf_file_revision.dmsf_file.last_revision.deleted?
      puts assignment.dmsf_file_revision.workflow
      puts "#{assignment.dmsf_file_revision.id} == #{assignment.dmsf_file_revision.dmsf_file.last_revision.id}"
      if assignment.dmsf_file_revision.dmsf_file.last_revision &&
        !assignment.dmsf_file_revision.dmsf_file.last_revision.deleted? &&
        (assignment.dmsf_file_revision.workflow == DmsfWorkflow::STATE_WAITING_FOR_APPROVAL) &&
        (assignment.dmsf_file_revision.id == assignment.dmsf_file_revision.dmsf_file.last_revision.id)
        assignments << assignment
        puts 'yes'
      else
        puts 'no'
      end
    end
    puts "open assignments count: #{assignments.size}"
    ###
    @user_member.pref[:my_page_layout] = { 'top' => ['open_approvals'] }
    @user_member.pref.save!    
    get :page
    assert_response :success
    unless defined?(EasyExtensions)
      assert_select 'div#list-top' do
        assert_select 'h3', { :text => "#{l(:open_approvals)} (1)" }
      end
    end
  end
  
  def test_page_with_open_locked_documents    
    @user_member.pref[:my_page_layout] = { 'top' => ['locked_documents'] }
    @user_member.pref.save!    
    get :page
    assert_response :success
    unless defined?(EasyExtensions)
      assert_select 'div#list-top' do
        assert_select 'h3', { :text => "#{l(:locked_documents)} (0/1)" }
      end
    end
  end

end