# encoding: utf-8
require "sprockets"
require "tilt"

module Sprockets
  class JSMinifier < Tilt::Template
    def prepare
    end

    def evaluate(context, locals, &block)
      Uglifier.compile(data, :comments => :none)
    end
  end
end

module Padrino
  module Sprockets
    module Helpers
      module ClassMethods
        def sprockets(options={})

          _root = options[:root] || root
          paths = options[:paths] || []
          options[:root] = _root
          options[:paths] = paths
          use Padrino::Sprockets::App, options
        end
      end

      module AssetTagHelpers
        # Change the folders to /assets/
        def asset_folder_name(kind)
          # logger.info "including asset of kind: #{kind}" if settings.assets_debug
          case kind
          when :font then settings.assets_url
          when :css then settings.assets_url
          when :js  then settings.assets_url
          when :image  then settings.assets_url
          else kind.to_s
          end
        end
      end # AssetTagHelpers

      def self.included(base)
        base.send(:include, AssetTagHelpers)
        base.extend ClassMethods
      end
    end #Helpers

    class App
      attr_reader :assets
      attr_reader :matcher

      def initialize(app, options={})
        @app = app
        @root = options[:root] || Padrino.root
        url = app.settings.assets_url
        logger.info "root: #{@root}, asset-url: #{url}" if @app.settings.assets_debug
        @matcher = /^\/#{url}\/*/
        setup_environment(options[:minify], options[:paths] || [])
      end

      def setup_environment(minify=false, extra_paths=[])
        @assets = ::Sprockets::Environment.new
        @assets.append_path 'app/assets/javascripts'
        @assets.append_path 'app/assets/stylesheets'
        @assets.append_path 'vendor/assets/javascripts'
        @assets.append_path 'vendor/assets/stylesheets'

        if minify
          @assets.css_compressor = :scss
          if defined?(Uglifier)
            @assets.js_compressor = :uglify
            # @assets.register_postprocessor "application/javascript", ::Sprockets::JSMinifier
          else
            logger.error "Add uglifier to your Gemfile to enable js minification"
          end
        end

        extra_paths.each do |sprocket_path|
          @assets.append_path sprocket_path
        end
      end

      def call(env)
        logger.info "accessing: #{env["PATH_INFO"]}" if @app.settings.assets_debug
        if @matcher =~ env["PATH_INFO"]
          env['PATH_INFO'].sub!(@matcher,'')
          logger.info "matched: #{env['PATH_INFO'].inspect}" if @app.settings.assets_debug
          @assets.call(env)
        else
          @app.call(env)
        end
      end
    end

    class << self
      def registered(app)
        app.helpers Padrino::Sprockets::Helpers
      end
    end
  end #Sprockets
end #Padrino
