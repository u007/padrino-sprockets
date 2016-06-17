# encoding: utf-8
require "sprockets/helpers"
# require "padrino-helpers"
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


    # Sprockets
    class App
      attr_reader :asset_env
      attr_reader :matcher

      def initialize(app, options={})
        @app = app
        # puts "root: #{Padrino.root}"
        @root = options[:root] || Padrino.root
        @asset_path = app.settings.assets_path || Padrino.root(app.settings.public_folder+"/assets")
        @compile = app.settings.assets_compile.nil? ? true: app.settings.assets_compile
        url = app.settings.assets_url
        logger.info "root: #{@root}, asset-url: #{url}" if app.settings.assets_debug
        @matcher = /^#{url}\/*/
        @asset_env = Sprockets.setup_environment(app, options[:minify], options[:paths] || [])
        @manifest = ::Sprockets::Manifest.new(@asset_env, "#{@asset_path}/manifest.json")

        # logger.info "loaded sprockets rake"
        Padrino::Tasks.files << Dir[File.dirname(__FILE__) + '/tasks/**/*.rake']
        Padrino::Tasks.files << Dir[File.dirname(__FILE__) + '/tasks/*.rake']

        # cannot use this
        ::Sprockets::Helpers.configure do |config|
          config.environment = @asset_env
          config.prefix      = app.settings.assets_url
          config.digest      = true
          config.public_path = app.settings.public_folder

          # Force to debug mode in development mode
          # Debug mode automatically sets
          # expand = true, digest = false, manifest = false
          config.debug       = app.settings.assets_compile
        end

      end

      def call(env)
        logger.info "accessing: #{env["PATH_INFO"]}" if @app.settings.assets_debug
        if @matcher =~ env["PATH_INFO"]
          uri = env['PATH_INFO'].to_s # for some weird reason env['path_info'] is persisted in uri
          # logger.info "matched: #{uri}" if @app.settings.assets_debug
          # PryDebug.start_pry binding
          # binding.pry
          if !@compile
            # dont compile
            path_info = env['PATH_INFO'].sub(@matcher,'')
            ori_file = Rack::Utils.unescape(path_info.to_s.sub(/^\//, ''))
            logger.info "name: #{ori_file.inspect}" if @app.settings.assets_debug
            path = @manifest.assets[ori_file]
            if path
              if env['REQUEST_METHOD'] != 'GET'
                return method_not_allowed_response
              end
              env["PATH_INFO"] = uri[0, uri.length-ori_file.length] + path
              logger.info "new uri: #{env['PATH_INFO']}" if @app.settings.assets_debug
              #replacing ending with new path
              # env["PATH_INFO"] = path
            end
            return @app.call(env)
          else
            env['PATH_INFO'].sub!(@matcher,'')
            # compile from paths
            res = @asset_env.call(env)
            # logger.info "lookup: #{uri}: #{res.inspect}"
            if res[0] == 200
              return res
            else
              env['PATH_INFO'] = "/"+env['PATH_INFO']
              logger.info "fallback: #{env['PATH_INFO']}" if @app.settings.assets_debug
              # not exists, use public
              return @app.call(env)
            end
          end

        else
          @app.call(env)
        end
      end

      # https://github.com/rails/sprockets/blob/9db6aa1c8bec0c445c58d2783d7166f7c44a58f0/lib/sprockets/server.rb
      def ok_response(asset, env)
        if head_request?(env)
          [ 200, headers(env, asset, 0), [] ]
        else
          # @manifest.find(asset)
          # binding.pry
          # [ 200, headers(env, asset, asset.length), asset ]
          [ 200, {}, [asset]]
        end
      end

      def method_not_allowed_response
        [ 405, { "Content-Type" => "text/plain", "Content-Length" => "18" }, [ "Method Not Allowed" ] ]
      end

      # Returns a 404 Not Found response tuple
      def not_found_response(env)
        if head_request?(env)
          [ 404, { "Content-Type" => "text/plain", "Content-Length" => "0", "X-Cascade" => "pass" }, [] ]
        else
          [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9", "X-Cascade" => "pass" }, [ "Not found" ] ]
        end
      end

      def headers(env, asset, length)
        headers = {}

        # Set content length header
        headers["Content-Length"] = length.to_s

        # Set content type header
        if type = asset.content_type
          # Set charset param for text/* mime types
          if type.start_with?("text/") && asset.charset
            type += "; charset=#{asset.charset}"
          end
          headers["Content-Type"] = type
        end

        headers.merge(cache_headers(env, asset.etag))
      end

      def head_request?(env)
        env['REQUEST_METHOD'] == 'HEAD'
      end

      def cache_headers(env, etag)
        headers = {}

        # Set caching headers
        headers["Cache-Control"] = String.new("public")
        headers["ETag"]          = %("#{etag}")

        # If the request url contains a fingerprint, set a long
        # expires on the response
        if path_fingerprint(env["PATH_INFO"])
          headers["Cache-Control"] << ", max-age=31536000"

        # Otherwise set `must-revalidate` since the asset could be modified.
        else
          headers["Cache-Control"] << ", must-revalidate"
          headers["Vary"] = "Accept-Encoding"
        end

        headers
      end

    end

    class << self
      attr_accessor :env
      def registered(app)
        app.helpers Padrino::Sprockets::Helpers
      end

      def setup_environment(app, minify=false, extra_paths=[])
        @env = ::Sprockets::Environment.new
        @env.append_path 'app/assets/images'
        @env.append_path 'app/assets/fonts'
        @env.append_path 'app/assets/javascripts'
        @env.append_path 'app/assets/stylesheets'
        @env.append_path 'vendor/assets/javascripts'
        @env.append_path 'vendor/assets/stylesheets'
        @env.append_path 'vendor/assets/images'
        @env.append_path 'vendor/assets/fonts'

        if minify
          @env.css_compressor = :scss
          if defined?(Uglifier)
            @env.js_compressor = :uglify
            # @asset_env.register_postprocessor "application/javascript", ::Sprockets::JSMinifier
          else
            logger.error "Add uglifier to your Gemfile to enable js minification"
          end
        end

        extra_paths.each do |sprocket_path|
          @env.append_path sprocket_path
        end

        @env
        # if app.settings.assets_compile
        #   @env
        # else
        #   @env.cached
        # end
      end

      def environment
        if @env.nil?
          @env = setup_environment(Padrino.mounted_apps[0])
        end
        @env
      end
    end
  end #Sprockets
end #Padrino
