module RedmineDmsf
	module Patches
		module ProjectPatch
			def all_dmsf_custom_fields
				@all_dmsf_custom_fields ||= (DmsfFileRevisionCustomField.for_all + dmsf_file_revision_custom_fields).uniq.sort
			end
		end
	end
end