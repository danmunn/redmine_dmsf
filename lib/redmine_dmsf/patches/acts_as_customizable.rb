module Redmine
	module Acts
		module Customizable
			module InstanceMethods
				def available_custom_fields
					cf_classname = self.class.name == 'DmsfFolder' ? 'DmsfFileRevision' : self.class.name
					CustomField.find(:all, :conditions => "type = '#{cf_classname}CustomField'", :order => 'position')
				end

				def show_custom_field_values
					custom_field_values.delete_if { |x| (!x.id && x.id.blank?) || x.value.blank? }
				end
			end
		end
	end
end