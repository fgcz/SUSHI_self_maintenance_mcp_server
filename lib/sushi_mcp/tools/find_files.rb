require_relative 'base_tool'

module SushiMcp
  module Tools
    class FindFiles < BaseTool
      def name
        'find_files'
      end

      def description
        'Find files matching a glob pattern. Use this to locate specific files by name pattern.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            glob: {
              type: 'string',
              description: 'Glob pattern to match files (e.g., "**/*App.rb", "*.md")'
            },
            path: {
              type: 'string',
              description: 'Base path to search from (default: repo root)'
            },
            max_results: {
              type: 'integer',
              description: 'Maximum number of results to return (default: 100)'
            }
          },
          required: ['glob']
        }
      end

      def call(arguments)
        glob_pattern = arguments['glob']
        path = arguments['path'] || '.'
        max_results = arguments['max_results'] || 100

        begin
          abs_path = @safety ? @safety.validate_path(path) : File.expand_path(path)

          unless File.directory?(abs_path)
            return text_content("Error: Not a directory: #{path}")
          end

          # Build the full glob pattern
          full_pattern = File.join(abs_path, glob_pattern)
          matches = Dir.glob(full_pattern).sort

          # Filter out blocked files if safety is enabled
          if @safety
            matches = matches.reject do |file|
              begin
                @safety.validate_path(file)
                false
              rescue
                true
              end
            end
          end

          if matches.empty?
            return text_content("No files found matching '#{glob_pattern}' in #{path}")
          end

          # Make paths relative to abs_path for cleaner output
          relative_matches = matches.map { |m| m.sub("#{abs_path}/", '') }

          total = relative_matches.size
          if total > max_results
            output = relative_matches.first(max_results).join("\n")
            output += "\n... and #{total - max_results} more files."
          else
            output = relative_matches.join("\n")
          end

          text_content("Found #{total} files:\n#{output}")
        rescue StandardError => e
          text_content("Error: #{e.message}")
        end
      end
    end
  end
end
