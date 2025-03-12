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
require 'rmagick'

module RedmineDmsf
  # Watermark
  module Watermark
    COLOR = '3c3c3c'
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
      # Add the watermark
      image = Magick::Image.read(source).first
      mark = Magick::Image.new(image.columns, image.rows) do |options|
        options.background_color = 'Transparent'
      end
      water_mark = watermark_image
      water_mark.annotate(mark, 0, 0, 0, 0, text) do |options|
        options.fill = "##{COLOR}"
        options.pointsize = 120
      end
      image.composite! mark, Magick::NorthGravity, Magick::HardLightCompositeOp
      image.write target
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
      pdf.fill_color COLOR
      pdf.transparent(0.4) do
        pdf.text text(true), align: :center, valign: :center, size: 36, rotate: -ANGLE
      end
      CombinePDF.parse(pdf.render).pages[0]
    end

    def self.watermark_image
      # Generate an image watermark
      water_mark = Magick::Draw.new
      water_mark.rotation = ANGLE
      water_mark.gravity = Magick::CenterGravity
      water_mark.font_family = 'Helvetica'
      water_mark.font_weight = Magick::BoldWeight
      water_mark
    end
  end
end
