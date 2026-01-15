require_relative 'base_tool'
require_relative '../app_parser'

module SushiMcp
  module Tools
    class CompareApps < BaseTool
      def name
        'compare_apps'
      end

      def description
        'Compare two SUSHI Apps to see their differences in parameters, modules, required columns, etc. Useful for understanding variations between similar apps.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            app1: {
              type: 'string',
              description: 'Name of the first SUSHI App'
            },
            app2: {
              type: 'string',
              description: 'Name of the second SUSHI App'
            }
          },
          required: ['app1', 'app2']
        }
      end

      def call(arguments)
        app1_name = arguments['app1']
        app2_name = arguments['app2']

        unless app1_name && app2_name
          return text_content("Error: Both app1 and app2 are required")
        end

        parser = AppParser.new
        comparison = parser.compare_apps(app1_name, app2_name)

        if comparison.nil?
          app1_exists = parser.parse_app(app1_name)
          app2_exists = parser.parse_app(app2_name)
          
          errors = []
          errors << "'#{app1_name}' not found" unless app1_exists
          errors << "'#{app2_name}' not found" unless app2_exists
          
          return text_content("Error: #{errors.join(' and ')}")
        end

        output = format_comparison(comparison, parser)
        text_content(output)
      end

      private

      def format_comparison(c, parser)
        app1 = parser.parse_app(c[:app1])
        app2 = parser.parse_app(c[:app2])
        diff = c[:differences]

        output = <<~OUTPUT
          # Comparison: #{c[:app1]} vs #{c[:app2]}

          ## Basic Info
          | Property | #{c[:app1]} | #{c[:app2]} |
          |----------|-------------|-------------|
          | Name | #{app1.name} | #{app2.name} |
          | Category | #{diff[:analysis_category][0] || 'N/A'} | #{diff[:analysis_category][1] || 'N/A'} |
          | Process Mode | #{diff[:process_mode][0] || 'N/A'} | #{diff[:process_mode][1] || 'N/A'} |
          | ezRun App | #{app1.ezrun_app || 'N/A'} | #{app2.ezrun_app || 'N/A'} |

          ## Required Columns
        OUTPUT

        rc = diff[:required_columns]
        if rc[:only_in_app1].empty? && rc[:only_in_app2].empty?
          output += "Both apps have identical required columns: #{rc[:common].join(', ')}\n"
        else
          output += "- **Common**: #{rc[:common].empty? ? 'None' : rc[:common].join(', ')}\n"
          output += "- **Only in #{c[:app1]}**: #{rc[:only_in_app1].empty? ? 'None' : rc[:only_in_app1].join(', ')}\n"
          output += "- **Only in #{c[:app2]}**: #{rc[:only_in_app2].empty? ? 'None' : rc[:only_in_app2].join(', ')}\n"
        end

        output += "\n## Modules\n"
        mod = diff[:modules]
        if mod[:only_in_app1].empty? && mod[:only_in_app2].empty?
          output += "Both apps use identical modules: #{mod[:common].join(', ')}\n"
        else
          output += "- **Common**: #{mod[:common].empty? ? 'None' : mod[:common].join(', ')}\n"
          output += "- **Only in #{c[:app1]}**: #{mod[:only_in_app1].empty? ? 'None' : mod[:only_in_app1].join(', ')}\n"
          output += "- **Only in #{c[:app2]}**: #{mod[:only_in_app2].empty? ? 'None' : mod[:only_in_app2].join(', ')}\n"
        end

        output += "\n## Parameters\n"
        params = diff[:params]
        if params[:only_in_app1].empty? && params[:only_in_app2].empty?
          output += "Both apps have the same parameter keys.\n"
        else
          output += "- **Common**: #{params[:common].size} parameters\n"
          output += "- **Only in #{c[:app1]}**: #{params[:only_in_app1].empty? ? 'None' : params[:only_in_app1].join(', ')}\n"
          output += "- **Only in #{c[:app2]}**: #{params[:only_in_app2].empty? ? 'None' : params[:only_in_app2].join(', ')}\n"
        end

        output += "\n## Methods\n"
        methods = diff[:methods]
        if methods[:only_in_app1].empty? && methods[:only_in_app2].empty?
          output += "Both apps define the same methods: #{methods[:common].join(', ')}\n"
        else
          output += "- **Common**: #{methods[:common].join(', ')}\n"
          output += "- **Only in #{c[:app1]}**: #{methods[:only_in_app1].empty? ? 'None' : methods[:only_in_app1].join(', ')}\n"
          output += "- **Only in #{c[:app2]}**: #{methods[:only_in_app2].empty? ? 'None' : methods[:only_in_app2].join(', ')}\n"
        end

        output
      end
    end
  end
end
