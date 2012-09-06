# == Schema Information
#
# Table name: dmsf_entities
#
#  id            :integer          not null, primary key
#  project_id    :integer          not null
#  parent_id     :integer
#  title         :string(255)      not null
#  description   :text
#  notification  :boolean          default(FALSE), not null
#  owner_id      :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  lft           :integer
#  rgt           :integer
#  depth         :integer
#  type          :string(255)
#  deleted_by_id :integer
#  deleted       :boolean          default(FALSE), not null
#

module Dmsf
  class File < Entity
    has_many :revisions
  end
end
