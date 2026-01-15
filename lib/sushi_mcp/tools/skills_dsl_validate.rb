require_relative 'base_tool'
require_relative '../dsl_skills_provider'

module SushiMcp
  module Tools
    class SkillsDslValidate < BaseTool
      def name
        'skills_dsl_validate'
      end

      def description
        'Validate the Skills DSL definition file using AST analysis.'
      end

      def input_schema
        {
          type: 'object',
          properties: {}
        }
      end

      def call(arguments)
        provider = DslSkillsProvider.new
        errors = provider.validate

        if errors.empty?
          text_content("Validation passed. Skills DSL is valid.")
        else
          error_msg = "Validation failed with #{errors.size} error(s):\n\n"
          errors.each do |error|
            error_msg += "- #{error}\n"
          end
          text_content(error_msg)
        end
      end
    end
  end
end
