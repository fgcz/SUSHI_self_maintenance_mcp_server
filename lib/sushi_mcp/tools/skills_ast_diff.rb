require_relative 'base_tool'
require_relative '../skills_ast'

module SushiMcp
  module Tools
    class SkillsAstDiff < BaseTool
      def name
        'skills_ast_diff'
      end

      def description
        'Compare two versions of the Skills DSL file and show semantic differences. Provide paths to old and new versions.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            old_path: {
              type: 'string',
              description: 'Path to the old version of skills.rb (optional, defaults to current)'
            },
            new_path: {
              type: 'string',
              description: 'Path to the new version of skills.rb (optional)'
            }
          }
        }
      end

      def call(arguments)
        old_path = arguments['old_path']
        new_path = arguments['new_path']

        # If no paths provided, show a placeholder message
        if old_path.nil? && new_path.nil?
          return text_content(<<~MSG)
            Skills AST Diff Tool

            This tool compares two versions of the Skills DSL file and shows semantic differences.

            Usage:
            - Provide old_path and new_path to compare two specific files
            - This enables tracking skill evolution over time

            Note: Full diff implementation requires storing historical AST snapshots.
            Current implementation is a placeholder for future development.
          MSG
        end

        begin
          old_ast = SkillsAst.parse(old_path) if old_path
          new_ast = SkillsAst.parse(new_path) if new_path

          diff_result = SkillsAst.diff(old_ast, new_ast)
          text_content("AST Diff Result:\n\n#{diff_result}")
        rescue => e
          text_content("Error comparing AST: #{e.message}")
        end
      end
    end
  end
end
