# == Schema Information
#
# Table name: dmsf_workflow
#
#  id                 :integer          not null, primary key
#  name               :string(255)      not null
#  project_id         :integer          not null
#

module Dmsf
  class Workflow < ActiveRecord::Base
    belongs_to :project

    has_many :workflow_steps, :dependent => :destroy

    validates_uniqueness_of :name
    validates :name, :presence => true
    validates_length_of :name, :maximum => 255

    def self.workflows(project)
      if project
        where(['project_id = ?', project])
      else
        where('project_id IS NULL')
      end
    end

    def to_s
      name
    end
  end
end