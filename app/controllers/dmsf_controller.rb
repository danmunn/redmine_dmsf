
class DmsfController < ApplicationController
  unloadable

  before_filter :match_project
  before_filter :match_path
  helper :dmsf

  def index
    #If path is not set (root) or path is empty
    if @path.nil? || @path.empty?

      #Called without any form of pathing?

      # ToDo: dmsf should implement its own 404 (type) page
      return render_404 if params[:dmsf_path]

      @entity = Dmsf::Folder.new(:project => @project)
      @items = @entity.Acl.visible_siblings
    else

      @entity = @path.last
      @parent = @entity.parent || Dmsf::Folder.new
      @items = @entity.Acl.visible_children if @entity.kind_of?(Dmsf::Folder)
      @items ||= []
    end

    @items.sort! do |a,b|
      [b.type, a.title] <=> [a.type, b.title]
    end

  end

  def match_project
    @project = Project.find(params[:id])
  end

  def match_path
    @path = Dmsf::Path.find(params[:dmsf_path], @project) unless params[:dmsf_path].nil?
    @path = [] if @path.nil?
  end
end