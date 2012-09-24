# == Schema Information
#
# Table name: dmsf_revisions
#
#  id                 :integer          not null, primary key
#  file_id            :integer          not null
#  source_revision_id :integer
#  title              :string(255)      not null
#  source_path        :string(255)      not null
#  size               :integer
#  mime_type          :string(255)
#  description        :text
#  workflow_id        :integer
#  major_version      :integer          not null
#  minor_version      :integer          not null
#  comment            :text
#  deleted            :boolean          default(FALSE), not null
#  deleted_by_id      :integer
#  owner_id           :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  project_id         :integer          not null
#

module Dmsf
  class Revision < Dmsf::ActiveRecordBase
    belongs_to :file
    belongs_to :owner, :class_name => 'User'
    belongs_to :deleted_by, :class_name => 'User'
    belongs_to :project
    belongs_to :source_revision, :class_name => 'Revision'
    has_many :accesses, :as => :relation, :class_name => Dmsf::Audit::Access

    scope :visible, where(:deleted => false)
    scope :deleted, where(:deleted => true)

    #Todo: belongs_to :workflow

  end
end
