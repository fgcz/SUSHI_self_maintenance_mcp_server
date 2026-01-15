require_relative 'base_tool'
require 'open3'

module SushiMcp
  module Tools
    class SearchRepo < BaseTool
      def name
        'search_repo'
      end

      def description
        'Search for a text pattern in the repository using ripgrep. Use this to find code definitions, usages, or specific strings.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'The pattern to search for (regex supported by ripgrep)'
            },
            path: {
              type: 'string',
              description: 'Relative path to limit search scope (optional, defaults to root)'
            },
            max_results: {
              type: 'integer',
              description: 'Maximum number of lines to return (optional, default: 50)'
            }
          },
          required: ['query']
        }
      end

      def call(arguments)
        query = arguments['query']
        path = arguments['path'] || '.'
        max_results = arguments['max_results'] || @safety&.max_search_lines || 50

        # Validate path
        begin
          abs_path = @safety ? @safety.validate_path(path) : File.expand_path(path)
        rescue StandardError => e
          return text_content("Error: #{e.message}")
        end

        # Try ripgrep first, fall back to grep
        stdout, stderr, status = run_search(query, abs_path)
        
        if status.success?
          lines = stdout.lines
          count = lines.size
          
          if count > max_results
            truncated = lines.first(max_results)
            truncated << "... and #{count - max_results} more matches. Please refine your query or path."
            text_content(truncated.join)
          elsif count == 0
            text_content("No matches found for '#{query}' in #{path}")
          else
            text_content(stdout)
          end
        else
          # Both rg and grep return exit code 1 if no matches found
          if status.exitstatus == 1 && stderr.empty?
             text_content("No matches found for '#{query}' in #{path}")
          else
             text_content("Error running search: #{stderr}")
          end
        end
      end

      private

      def run_search(query, path)
        # Try ripgrep first
        if system('which rg > /dev/null 2>&1')
          cmd = ['rg', '-n', '--no-heading', '-H', query, path]
        else
          # Fallback to grep
          cmd = ['grep', '-r', '-n', '-H', query, path]
        end
        
        Open3.capture3(*cmd)
      end
    end
  end
end
