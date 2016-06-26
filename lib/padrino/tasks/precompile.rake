# require 'padrino-helpers'
require "sprockets"
require 'rake'
require 'rake/tasklib'
require "tilt"

namespace :assets do
  desc 'Compiles all assets'
  task :precompile => :environment do
    apps = Padrino.mounted_apps
    # puts "running on #{apps.inspect}"
    apps.each do |app|
      app = app.app_obj
      task = Padrino::Sprockets::PrecompileTask.new(app)
      task.compile
    end
  end

  task :clean => :environment do
    apps.each do |app|
      app = app.app_obj
      task = Padrino::Sprockets::PrecompileTask.new(app)
      task.clean
    end
  end

  task :compress => :environment do
    apps.each do |app|
      app = app.app_obj
      task = Padrino::Sprockets::PrecompileTask.new(app)
      task.compress
    end
  end

  task :clobber => :environment do
    apps.each do |app|
      app = app.app_obj
      task = Padrino::Sprockets::PrecompileTask.new(app)
      task.clobber
    end
  end
end # namespace

module Padrino
  module Sprockets
    class PrecompileTask < Rake::TaskLib
      def initialize(app)
        @app = app
        @asset_env = ::Sprockets::Environment.new
        @asset_env.append_path 'app/assets/javascripts'
        @asset_env.append_path 'app/assets/stylesheets'
        @asset_env.append_path 'vendor/assets/javascripts'
        @asset_env.append_path 'vendor/assets/stylesheets'

        @asset_path = app.settings.assets_path || Padrino.root("public/assets")
        @minify = true

        if @minify
          @asset_env.css_compressor = :scss
          if defined?(Uglifier)
            @asset_env.js_compressor = :uglify
            # @assets.register_postprocessor "application/javascript", ::Sprockets::JSMinifier
          else
            logger.error "Add uglifier to your Gemfile to enable js minification"
          end
        end
        @manifest = ::Sprockets::Manifest.new(@asset_env, "#{@asset_path}/manifest.json")
      end#initialize

      def compile
        puts "compiling to: #{@asset_path}"
        @manifest.compile(@app.settings.assets_precompile)
      end

      def clean
        @manifest.cleanup()
        # FileUtils.rm_rf(@asset_path)
      end

      def compress
        @manifest.assets.each do |asset, digested_asset|
          if asset = @asset_env[asset]
            compressed_asset = File.join(manifest.dir, digested_asset)
            asset.write_to(compressed_asset + '.gz') if compressed_asset =~ /\.(?:css|html|js|svg|txt|xml)$/
          end
        end
      end

      def clobber
        @manifest.clobber()
        # FileUtils.rm_rf(@asset_path)
      end

    end # PrecompileTask

  end # Sprockets
end # Padrino
