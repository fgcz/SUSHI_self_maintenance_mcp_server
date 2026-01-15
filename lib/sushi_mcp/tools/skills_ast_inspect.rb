require_relative 'base_tool'
require_relative '../dsl_skills_provider'

module SushiMcp
  module Tools
    class SkillsAstInspect < BaseTool
      def name
        'skills_ast_inspect'
      end

      def description
        'Inspect the Ruby AST structure of the Skills DSL file. Useful for debugging and verification.'
      end

      def input_schema
        {
          type: 'object',
          properties: {}
        }
      end

      def call(arguments)
        provider = DslSkillsProvider.new
        ast = provider.ast

        output = format_ast_node(ast, 0)
        text_content("Skills DSL AST Structure:\n\n```\n#{output}\n```")
      end

      private

      def format_ast_node(node, depth)
        return "nil" if node.nil?
        return node.inspect unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)

        indent = "  " * depth
        result = "#{indent}#{node.type}"

        if node.children.any?
          result += " [\n"
          node.children.each_with_index do |child, i|
            if child.is_a?(RubyVM::AbstractSyntaxTree::Node)
              result += format_ast_node(child, depth + 1) + "\n"
            else
              result += "#{indent}  #{child.inspect}\n"
            end
          end
          result += "#{indent}]"
        end

        result
      end
    end
  end
end
