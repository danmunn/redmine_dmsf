# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-22 Karel Pičman <karel.picman@kontron.com>
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

module RedmineDmsf
  module Preview
    extend Redmine::Utils::Shell
    include Redmine::I18n

    OFFICE_BIN = (Setting.plugin_redmine_dmsf['office_bin'] || 'libreoffice').freeze

    def self.office_available?
      if defined?(@office_available)
        return @office_available
      end
      begin
        `#{shell_quote OFFICE_BIN} --version`
        @office_available = $?.success?
      rescue
        @office_available = false
      end
      unless @office_available
        Rails.logger.warn l(:note_dmsf_office_bin_not_available, value: OFFICE_BIN, locale: :en)
      end
      @office_available
    end

    def self.generate(source, target)
      if File.exist?(target)
        target
      else
        dir = File.dirname(target)
        cmd = "#{shell_quote(OFFICE_BIN)} --convert-to pdf --headless --outdir #{shell_quote(dir)} #{shell_quote(source)}"
        if system(cmd)
          target
        else
          Rails.logger.error "Creating preview failed (#{$?}):\nCommand: #{cmd}"
          ''
        end
      end
    end

  end

end
