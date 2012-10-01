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

    # Return the latest revision from collection of revisions on file
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +Dmsf::Revision+ -> Located last revision
    #   - +Nil+ -> nil returned when no revisions are to be returned.
    #
    def last_revision
      return @last_revision unless @last_revision.nil?
      @last_revision = revisions.visible.last
    end

    # Return the title for either the file object or the last revisions
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +String+ -> Title of file
    #
    def title
      last_revision.nil? ? self.title : last_revision.title
    end

  end
end
