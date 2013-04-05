require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'capybara-webkit'
require 'prawn'

module Ducksboard

  class CapybaraInstance
    include Capybara::DSL

    def setup_capybara
      Capybara.run_server        = false
      Capybara.current_driver    = :webkit
      Capybara.javascript_driver = :webkit
      Capybara.app_host          = 'https://public.ducksboard.com'
    end

    def render_to_png(dashboard_id,filename)
      setup_capybara
      visit "/#{dashboard_id}"
      page.find 'div.dashboard.ready' # wait until the 'ready' class is available
      sleep 5 # wait for effects/fade in (WARNING: THIS IS BLOCKING! DON'T USE IN A SYNCHRONOUS CONTEXT)
      Capybara.save_screenshot filename
    end
  end

  class PDFGenerator

    def self.render_to_png(dashboard_id,filename)
      CapybaraInstance.new.render_to_png(dashboard_id,filename)
    end

    def self.default_filename(dashboard_id)
      FileUtils.mkdir './out' unless File.directory?('./out')
      filename = "./out/Dashboard-#{dashboard_id}-#{Time.now.strftime('%Y-%m-%d')}"
    end

    def self.render(dashboard_id,filename=nil)
      filename = default_filename(dashboard_id) if filename.nil?
      render_to_png dashboard_id, "#{filename}.png"
      render_to_pdf "#{filename}.png", "#{filename}.pdf"
    end

    def self.render_to_pdf(image_filename,pdf_filename,options={})
      options  = { page_size: 'A4', page_layout: :landscape, margin: 0 }.merge(options)
      geometry = Prawn::Document::PageGeometry::SIZES[options[:page_size]]
      geometry = geometry.reverse if options[:page_layout] == :landscape
      position = [ 0, geometry[1] ]
      Prawn::Document.generate pdf_filename, options do
        image image_filename, :at => position, :fit => geometry
      end
    end
  end
end