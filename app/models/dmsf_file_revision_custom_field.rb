class DmsfFileRevisionCustomField < CustomField
  unloadable
  has_and_belongs_to_many :projects, :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}", :foreign_key => "custom_field_id"

  def initialize(attributes = nil)
    super
    self.searchable = true
  end

  def type_name
    :DMSF_custom_field
  end
end