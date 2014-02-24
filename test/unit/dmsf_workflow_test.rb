# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2013   Karel Picman <karel.picman@kontron.com>
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

class DmsfWorkflowTest < RedmineDmsf::Test::UnitTest

  fixtures :projects, :members, :dmsf_files, :dmsf_file_revisions, 
    :dmsf_workflows, :dmsf_workflow_steps, :dmsf_workflow_step_assignments,
    :dmsf_workflow_step_actions

  def setup
    User.current = User.find_by_id 1  # Admin   
    @wf1 = DmsfWorkflow.find_by_id(1)
    @wf2 = DmsfWorkflow.find_by_id(2) 
    @wfs1 = DmsfWorkflowStep.find_by_id(1)
    @wfs2 = DmsfWorkflowStep.find_by_id(2)
    @wfs3 = DmsfWorkflowStep.find_by_id(3)
    @wfs4 = DmsfWorkflowStep.find_by_id(4)
    @wfs5 = DmsfWorkflowStep.find_by_id(5)
    @wfsa1 = DmsfWorkflowStepAssignment.find_by_id(1)
    @wfsac1 = DmsfWorkflowStepAction.find_by_id(1)
    @revision1 = DmsfFileRevision.find_by_id 1
    @revision2 = DmsfFileRevision.find_by_id 2
    @project = Project.find_by_id 2
    @project5 = Project.find_by_id 5
  end
  
  def test_truth    
    assert_kind_of DmsfWorkflow, @wf1        
    assert_kind_of DmsfWorkflow, @wf2
    assert_kind_of DmsfWorkflowStep, @wfs1
    assert_kind_of DmsfWorkflowStep, @wfs2
    assert_kind_of DmsfWorkflowStep, @wfs3
    assert_kind_of DmsfWorkflowStep, @wfs4
    assert_kind_of DmsfWorkflowStep, @wfs5
    assert_kind_of DmsfWorkflowStepAssignment, @wfsa1
    assert_kind_of DmsfWorkflowStepAction, @wfsac1
    assert_kind_of DmsfFileRevision, @revision1
    assert_kind_of DmsfFileRevision, @revision2
    assert_kind_of Project, @project
    assert_kind_of Project, @project5
  end
  
  def test_create
    workflow = DmsfWorkflow.new(:name => 'wf')   
    assert workflow.save
  end
  
  def test_update    
    @wf1.name = 'wf1a'
    @wf1.project_id = 5
    assert @wf1.save
    @wf1.reload
    assert_equal 'wf1a', @wf1.name
    assert_equal 5, @wf1.project_id
  end
  
  def test_validate_name_length
    @wf1.name = 'a' * 256
    assert !@wf1.save
    assert_equal 1, @wf1.errors.count        
  end
  
  def test_validate_name_presence
    @wf1.name = ''
    assert !@wf1.save
    assert_equal 1, @wf1.errors.count        
  end
  
  def test_validate_name_uniqueness
    @wf2.name = @wf1.name
    assert !@wf2.save
    assert_equal 1, @wf2.errors.count        
  end
  
  def test_destroy      
    @wf1.destroy
    assert_nil DmsfWorkflow.find_by_id(1)
    assert_nil DmsfWorkflowStep.find_by_id(@wfs1.id)
  end
  
  def test_project
    # Global workflow
    assert_nil @wf2.project
    # Project workflow
    @wf2.project_id = 5
    assert @wf2.project
  end
  
  def test_to_s
    assert_equal @wf1.name, @wf1.to_s
  end    
  
  def test_reorder_steps_highest    
    @wf1.reorder_steps(3, 'highest')
    @wfs1.reload
    @wfs2.reload
    @wfs3.reload
    @wfs4.reload
    @wfs5.reload
    assert_equal @wfs5.step, 1
    assert_equal @wfs1.step, 2
    assert_equal @wfs4.step, 2
    assert_equal @wfs2.step, 3
    assert_equal @wfs3.step, 3        
  end
  
  def test_reorder_steps_higher    
    @wf1.reorder_steps(3, 'higher')
    @wfs1.reload
    @wfs2.reload
    @wfs3.reload
    @wfs4.reload
    @wfs5.reload
    assert_equal @wfs1.step, 1
    assert_equal @wfs4.step, 1
    assert_equal @wfs5.step, 2
    assert_equal @wfs2.step, 3
    assert_equal @wfs3.step, 3        
  end
  
  def test_reorder_steps_lower   
    @wf1.reorder_steps(1, 'lower')
    @wfs1.reload
    @wfs2.reload
    @wfs3.reload
    @wfs4.reload
    @wfs5.reload    
    assert_equal @wfs2.step, 1
    assert_equal @wfs3.step, 1    
    assert_equal @wfs1.step, 2
    assert_equal @wfs4.step, 2
    assert_equal @wfs5.step, 3
  end
  
  def test_reorder_steps_lowest    
    @wf1.reorder_steps(1, 'lowest')
    @wfs1.reload
    @wfs2.reload
    @wfs3.reload
    @wfs4.reload
    @wfs5.reload    
    assert_equal @wfs2.step, 1
    assert_equal @wfs3.step, 1    
    assert_equal @wfs5.step, 2
    assert_equal @wfs1.step, 3
    assert_equal @wfs4.step, 3
  end    
  
  def test_delegates    
    delegates = @wf1.delegates(nil, nil, nil)
    assert_equal(delegates.all.count + 1, @project5.users.all.count)
    delegates = @wf1.delegates('Dave', nil, nil)        
    assert_equal delegates.size, 1
    delegates = @wf1.delegates(nil, @wfsa1.id, 2)        
    assert !delegates.any?{|user| user.id == @wfsa1.user_id}
    assert delegates.any?{|user| user.id == 8}    
  end
  
  def test_next_assignments    
    assignments = @wf1.next_assignments(2)
    assert_equal assignments.size, 1
    assert_equal assignments[0].user_id, 2    
  end 
  
  def test_assignments_to_users_str    
    assignments = @wf1.next_assignments(2)
    str = DmsfWorkflow.assignments_to_users_str(assignments)
    assert_equal str, 'John Smith', str
  end
  
  def test_assign
    @wf1.assign(1)
    @wf1.dmsf_workflow_steps.each do |step|
      assert_kind_of DmsfWorkflowStepAssignment, DmsfWorkflowStepAssignment.where(
        :dmsf_workflow_step_id => step.id, :dmsf_file_revision_id => 1).first
    end    
  end
  
  def test_try_finish        
    @revision1.set_workflow @wf1.id, 'start'        
    @wf1.try_finish @revision1, @wfsac1, User.current.id
    @revision1.reload
    assert_equal @revision1.workflow, DmsfWorkflow::STATE_APPROVED
    @revision2.set_workflow @wf1.id, 'start'        
    @wf1.try_finish @revision2, @wfsac1, User.current.id
    assert_equal @revision2.workflow, DmsfWorkflow::STATE_WAITING_FOR_APPROVAL    
  end
  
  def test_participiants
    participiants = @wf1.participiants    
    assert_equal participiants.count, 2
  end
end
