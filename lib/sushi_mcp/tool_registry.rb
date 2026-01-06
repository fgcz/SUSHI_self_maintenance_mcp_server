require_relative 'tools/base_tool'
require_relative 'tools/hello_world'

module SushiMcp
  class ToolRegistry
    def initialize
      @tools = {}
      register_tools
    end

    def register_tools
      # Register available tools here
      # In Phase 1, we will auto-load from a directory
      register(Tools::HelloWorld.new)
    end

    def register(tool)
      @tools[tool.name] = tool
    end

    def list_tools
      @tools.values.map(&:to_schema)
    end

    def call_tool(name, arguments)
      tool = @tools[name]
      unless tool
        raise "Tool not found: #{name}"
      end

      tool.call(arguments)
    end
  end
end

