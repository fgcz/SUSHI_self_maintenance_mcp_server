require_relative 'base_tool'
require_relative '../skills_parser'

module SushiMcp
  module Tools
    class SkillsSearch < BaseTool
      def name
        'skills_search'
      end

      def description
        'Search SUSHI skills documentation for a keyword or topic. Returns matching sections with their content.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Search query (keyword or topic to find)'
            },
            max_sections: {
              type: 'integer',
              description: 'Maximum number of sections to return (default: 3)'
            }
          },
          required: ['query']
        }
      end

      def call(arguments)
        query = arguments['query']
        max_sections = arguments['max_sections'] || 3

        unless query && !query.empty?
          return text_content("Error: query is required")
        end

        parser = SkillsParser.new
        matches = parser.search_sections(query, max_sections)

        if matches.empty?
          return text_content("No sections found matching '#{query}'.\n\nTry using skills_list to see all available sections.")
        end

        output = "Found #{matches.size} section(s) matching '#{query}':\n\n"

        matches.each_with_index do |section, index|
          output += "---\n" if index > 0
          output += "## [#{section.id}] #{section.title}\n\n"
          
          # Truncate content if too long
          content = section.content
          if content.length > 2000
            content = content[0, 2000] + "\n\n... (content truncated, use skills_get('#{section.id}') for full content)"
          end
          output += content
          output += "\n"
        end

        text_content(output)
      end
    end
  end
end
