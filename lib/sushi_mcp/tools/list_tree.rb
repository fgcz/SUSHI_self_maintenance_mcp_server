require_relative 'base_tool'

module SushiMcp
  module Tools
    class ListTree < BaseTool
      def name
        'list_tree'
      end

      def description
        'List directory structure as a tree. Use this to understand the layout of the codebase.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Path to the directory to list (relative to repo root, default: root)'
            },
            depth: {
              type: 'integer',
              description: 'Maximum depth to traverse (default: 3)'
            }
          }
        }
      end

      def call(arguments)
        path = arguments['path'] || '.'
        max_depth = arguments['depth'] || 3
        max_depth = [@safety&.max_tree_depth || 5, max_depth].min

        begin
          abs_path = @safety ? @safety.validate_path(path) : File.expand_path(path)

          unless File.directory?(abs_path)
            return text_content("Error: Not a directory: #{path}")
          end

          tree_output = build_tree(abs_path, max_depth)
          text_content(tree_output)
        rescue StandardError => e
          text_content("Error: #{e.message}")
        end
      end

      private

      def build_tree(root, max_depth, prefix = '', current_depth = 0)
        return '' if current_depth > max_depth

        output = ''
        entries = Dir.entries(root).reject { |e| e.start_with?('.') }.sort

        entries.each_with_index do |entry, index|
          full_path = File.join(root, entry)
          is_last = index == entries.size - 1
          connector = is_last ? '└── ' : '├── '
          next_prefix = prefix + (is_last ? '    ' : '│   ')

          if File.directory?(full_path)
            output += "#{prefix}#{connector}#{entry}/\n"
            if current_depth < max_depth
              output += build_tree(full_path, max_depth, next_prefix, current_depth + 1)
            end
          else
            output += "#{prefix}#{connector}#{entry}\n"
          end
        end

        output
      end
    end
  end
end
