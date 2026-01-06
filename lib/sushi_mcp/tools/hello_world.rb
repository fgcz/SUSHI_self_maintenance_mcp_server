require_relative 'base_tool'

module SushiMcp
  module Tools
    class HelloWorld < BaseTool
      def name
        'hello_world'
      end

      def description
        'Returns a hello message from SUSHI MCP Server'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'Name to greet (optional)'
            }
          }
        }
      end

      def call(arguments)
        name = arguments['name'] || 'World'
        text_content("Hello, #{name}! This is SUSHI MCP Server (Phase 0).")
      end
    end
  end
end

