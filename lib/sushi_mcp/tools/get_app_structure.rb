require_relative 'base_tool'
require_relative '../app_parser'

module SushiMcp
  module Tools
    class GetAppStructure < BaseTool
      def name
        'get_app_structure'
      end

      def description
        'Analyze a SUSHI App and return its structure including parameters, required columns, modules, and methods. Use this to understand how an existing app is built.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            app_name: {
              type: 'string',
              description: 'Name of the SUSHI App (e.g., "FastqcApp" or "Fastqc")'
            }
          },
          required: ['app_name']
        }
      end

      def call(arguments)
        app_name = arguments['app_name']

        unless app_name && !app_name.empty?
          return text_content("Error: app_name is required")
        end

        parser = AppParser.new(@safety&.sushi_lib_path)
        structure = parser.parse_app(app_name)

        if structure.nil?
          available = parser.list_apps.first(20).join(', ')
          return text_content("App '#{app_name}' not found.\n\nAvailable apps (first 20): #{available}\n\nUse list_sushi_apps to see all apps.")
        end

        output = format_structure(structure)
        text_content(output)
      end

      private

      def format_structure(s)
        output = <<~OUTPUT
          # #{s.class_name} Structure Analysis

          ## Basic Info
          - **Name**: #{s.name || 'N/A'}
          - **Category**: #{s.analysis_category || 'N/A'}
          - **Process Mode**: #{s.process_mode || 'N/A'}
          - **ezRun App**: #{s.ezrun_app || 'N/A'}
          - **File**: #{s.file_path}

          ## Description
          #{s.description || 'No description'}

          ## Required Columns
          #{s.required_columns.empty? ? 'None' : s.required_columns.map { |c| "- #{c}" }.join("\n")}

          ## Required Parameters
          #{s.required_params.empty? ? 'None' : s.required_params.map { |p| "- #{p}" }.join("\n")}

          ## Parameters
        OUTPUT

        if s.params.empty?
          output += "No parameters defined\n"
        else
          s.params.each do |key, value|
            output += "- **#{key}**: #{value}\n"
          end
        end

        output += <<~OUTPUT

          ## Modules
          #{s.modules.empty? ? 'None' : s.modules.map { |m| "- #{m}" }.join("\n")}

          ## Inherited Columns
          #{s.inherit_columns.empty? ? 'None' : s.inherit_columns.map { |c| "- #{c}" }.join("\n")}

          ## Inherited Tags
          #{s.inherit_tags.empty? ? 'None' : s.inherit_tags.map { |t| "- #{t}" }.join("\n")}

          ## Methods
          #{s.methods.map { |m| "- #{m}" }.join("\n")}
        OUTPUT

        output
      end
    end
  end
end
