require_relative 'base_tool'

module SushiMcp
  module Tools
    class ReadFile < BaseTool
      def name
        'read_file'
      end

      def description
        'Read the contents of a file. Use this to examine code or configuration files.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Path to the file to read (relative to repo root)'
            },
            max_bytes: {
              type: 'integer',
              description: 'Maximum bytes to read (optional)'
            }
          },
          required: ['path']
        }
      end

      def call(arguments)
        path = arguments['path']
        limit = arguments['max_bytes'] || @safety&.max_read_bytes || 100_000

        begin
          abs_path = @safety ? @safety.validate_path(path) : File.expand_path(path)
          
          unless File.exist?(abs_path)
            return text_content("Error: File not found: #{path}")
          end

          if File.directory?(abs_path)
            return text_content("Error: Path is a directory: #{path}. Use list_tree to inspect directories.")
          end
          
          size = File.size(abs_path)
          if size > limit
             content = File.read(abs_path, limit)
             text_content("#{content}\n\n... (File truncated. Total size: #{size} bytes. Showing first #{limit} bytes)")
          else
             content = File.read(abs_path)
             text_content(content)
          end

        rescue StandardError => e
          text_content("Error: #{e.message}")
        end
      end
    end
  end
end
