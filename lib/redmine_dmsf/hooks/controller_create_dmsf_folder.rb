# Copyright (C) 2014   Jens Voegler 
module RedmineDmsf
  module Hooks    
    
    class ControllerCreateDmsfFolder < Redmine::Hook::ViewListener
      
      def controller_create_dmsf_folder(context={})
        @folder = DmsfFolder.new
        @folder.project = context[:project]
        @folder.user = context[:user]
        @folder.title = context[:title]
        @folder.save
        if !context[:subfolder_titles].nil?
          if !context[:subfolder_titles].empty?
            context[:subfolder_titles].split('|').each do |sf_title|
              #sf = subfolder not recursive
              sf = DmsfFolder.new 
              sf.project = context[:project]
              sf.user = context[:user]
              sf.title = sf_title
              sf.dmsf_folder_id = @folder.id
              sf.save 
            end
             message = context[:subfolder_titles].to_s
          else
            message = "subtitle is empty"
          end
        else
          message = "subtitle is nil"
        end
        return message
      end

    end
  end
end 