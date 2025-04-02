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
    ANGLE = 30

    def self.generate_pdf(source, target)
      # Add the watermark
      pdf = CombinePDF.load source
      width, height = get_min_pdf_page_size(pdf)
      watermark = watermark_pdf(width, height)
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

    def self.watermark_pdf(width, height)
      # Generate a PDF watermark
      pdf = Prawn::Document.new(page_size: [width, height])
      pdf.fill_color '808080'
      pdf.transparent(0.4) do
        pdf.text text(normalize: true),
                 align: :center,
                 valign: :top,
                 size: get_optimal_font_size(width, height),
                 rotate: -ANGLE
      end
      CombinePDF.parse(pdf.render).pages[0]
    end

    def self.watermark_img(source_image)
      img = MiniMagick::Image.create('.png')
      if Redmine::Configuration['imagemagick_convert_command'].present?
        MiniMagick.cli_path = File.dirname(Redmine::Configuration['imagemagick_convert_command'])
      end
      MiniMagick.convert do |gc|
        width = source_image.info(:width)
        height = source_image.info(:height)
        gc.size format('%<width>dx%<height>d', width: width, height: height)
        gc.xc 'transparent'
        # It is necessary to have gsfonts package installed or minimagick_font_path env specified
        gc.font Redmine::Configuration['minimagick_font_path'].presence || 'Helvetica'
        gc.fill 'gray'
        gc.strokewidth 1
        gc.pointsize get_optimal_point_size(width, height)
        gc.gravity 'center'
        gc.draw format("rotate %<angle>d text %<x>d,%<y>d '%<text>s'", angle: ANGLE, x: 0, y: 0, text: text)
        gc << img.path
      end
      img
    end

    def self.get_optimal_point_size(width, height)
      pointsize = [width, height].min / 10
      pointsize = 120 if pointsize > 120
      pointsize = 10 if pointsize < 10

      pointsize
    end

    def self.get_optimal_font_size(width, height)
      fontsize = ([width, height].min / 842.0 * 36.0).to_i
      fontsize = 36 if fontsize > 36
      fontsize = 10 if fontsize < 10

      fontsize
    end

    def self.get_min_pdf_page_size(pdf)
      width = 5950 # A4
      height = 8420
      pdf.pages.each do |page|
        width = [page.mediabox[2] - page.mediabox[0], width].min
        height = [page.mediabox[3] - page.mediabox[1], height].min
      end
      [width.to_i, height.to_i]
    end
  end
end
