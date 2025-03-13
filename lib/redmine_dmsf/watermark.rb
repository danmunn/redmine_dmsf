# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
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

require 'prawn'
require 'combine_pdf'

module RedmineDmsf
  # Watermark
  module Watermark
    ANGLE = 45

    def self.generate_pdf(source, target)
      # Add the watermark
      watermark = watermark_pdf
      pdf = CombinePDF.load source
      pdf.pages.each { |page| page << watermark }
      pdf.save target
      target
    end

    def self.generate_image(source, target)
      return target unless RedmineDmsf::Plugin.lib_available?('mini_magick')

      source_image = MiniMagick::Image.open(source)
      img = watermark_img(source_image)
      result = source_image.composite(img) do |c|
        c.compose 'multiply'
      end
      result.write target
      img.destroy!
      target
    end

    def self.text(normalize: false)
      text = "#{User.current}\n#{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
      if normalize
        text.unicode_normalize! :nfc
        text.encode! 'windows-1252', 'UTF-8', invalid: :replace, undef: :replace, replace: '?'
      end
      text
    end

    def self.watermark_pdf
      # Generate a PDF watermark
      pdf = Prawn::Document.new
      pdf.fill_color '808080'
      pdf.transparent(0.4) do
        pdf.text text(normalize: true), align: :center, valign: :center, size: 36, rotate: -ANGLE
      end
      CombinePDF.parse(pdf.render).pages[0]
    end

    def self.watermark_img(source_image)
      img = MiniMagick::Image.create('.png')
      if Redmine::Configuration['imagemagick_convert_command'].present?
        MiniMagick.cli_path = File.dirname(Redmine::Configuration['imagemagick_convert_command'])
      end
      MiniMagick.convert do |gc|
        gc.size format('%<width>dx%<height>d', width: source_image.info(:width), height: source_image.info(:height))
        gc.xc 'transparent'
        # It is necessary to have gsfonts package installed or minimagick_font_path env specified
        font_path = Redmine::Configuration['minimagick_font_path'].presence
        gc.font font_path.presence || 'Helvetica'
        gc.fill 'gray'
        gc.strokewidth 1
        gc.pointsize 120
        gc.gravity 'center'
        gc.draw format("rotate %<angle>d text %<x>d,%<y>d '%<text>s'", angle: ANGLE, x: 0, y: 0, text: text)
        gc << img.path
      end
      img
    end
  end
end
