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

class WorkflowStepAssignmentTest < RedmineDmsf::Test::UnitTest
  
  fixtures :users, :dmsf_file_revisions, :dmsf_workflow_steps, :dmsf_workflow_step_assignments
  
  def setup
    @wfsa1 = DmsfWorkflowStepAssignment.find(1)
    @wfsa2 = DmsfWorkflowStepAssignment.find(2)
  end
  
  def test_truth
    assert_kind_of DmsfWorkflowStepAssignment, @wfsa1
  end
  
  def test_create
    wfsa = DmsfWorkflowStepAssignment.new(      
      :dmsf_workflow_step_id => 5,
      :user_id => 2,
      :dmsf_file_revision_id => 2)   
    assert wfsa.save
  end
  
  def test_update    
    @wfsa1.dmsf_workflow_step_id = 5   
    @wfsa1.user_id = 2
    @wfsa1.dmsf_file_revision_id = 2
    
    assert @wfsa1.save
    @wfsa1.reload
    
    assert_equal 5, @wfsa1.dmsf_workflow_step_id    
    assert_equal 2, @wfsa1.user_id
    assert_equal 2, @wfsa1.dmsf_file_revision_id
  end
  
  def test_validate_workflow_step_id_presence
    @wfsa1.dmsf_workflow_step_id = nil
    assert !@wfsa1.save
    assert_equal 1, @wfsa1.errors.count        
  end
  
  def test_validate_workflow_entity_id_presence
    @wfsa1.dmsf_file_revision_id = nil
    assert !@wfsa1.save
    assert_equal 1, @wfsa1.errors.count        
  end
  
  def test_validate_dmsf_workflow_step_id_uniqueness    
    @wfsa1.dmsf_workflow_step_id = @wfsa2.dmsf_workflow_step_id
    @wfsa1.dmsf_file_revision_id = @wfsa2.dmsf_file_revision_id
    assert !@wfsa1.save
    assert_equal 1, @wfsa1.errors.count            
  end
  
  def test_destroy  
    @wfsa1.destroy
    assert_nil DmsfWorkflowStepAssignment.find_by_id(1)
    assert_nil DmsfWorkflowStepAction.find_by_id(1)
  end
end
