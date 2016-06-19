module Padrino
  module Processor
    class RiotProcessor

      RUNTIME = ::ExecJS::ExternalRuntime.new(
        name: 'Node.js (V8)',
        command: ['nodejs', 'node'],
        encoding: 'UTF-8',
        runner_path: File.expand_path('../../support/riot_node_runner.js', __FILE__),
      )
      COMPILER_PATH = File.expand_path('../../support/riot_compiler.js', __FILE__)
      VERSION = '1'

      def self.cache_key
        @cache_key ||= "#{name}:#{VERSION}".freeze
      end

      def self.call(input)
        logger.info "compiling riot: #{input.inspect}"
        data = input[:data]

        js, map = input[:cache].fetch([self.cache_key, data]) do
          result = compile(data, sourceMap: true, sourceFiles: [input[:source_path]])
          [result['js'], SourceMapUtils.decode_json_source_map(result['v3SourceMap'])['mappings']]
        end

        map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)
        { data: js, map: map }
      end



      def compile(source_code)
        source_code = escape_javascript(source_code)
        source_code = wrap_in_javascript_compiler(source_code)
        RUNTIME.exec(source_code)
      end

      private
      def wrap_in_javascript_compiler(source_code)
        <<-JS
          var compiler = require("#{COMPILER_PATH}");
          return compiler.compile("#{source_code}");
        JS
      end

    end
  end
end
