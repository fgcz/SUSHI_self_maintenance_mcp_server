require_relative 'safety'
require_relative 'tools/base_tool'

module SushiMcp
  class ToolRegistry
    def initialize
      @safety = Safety.new
      @tools = {}
      register_tools
    end

    def register_tools
      # Load all tool files
      Dir[File.join(__dir__, 'tools', '*.rb')].each do |file|
        require file
      end

      # Register tools
      # Note: We manually register for now to ensure proper instantiation order
      # In a larger system, we might use introspection
      
      register_if_defined('SushiMcp::Tools::HelloWorld')
      register_if_defined('SushiMcp::Tools::SearchRepo')
      register_if_defined('SushiMcp::Tools::ReadFile')
      register_if_defined('SushiMcp::Tools::ListTree')
      register_if_defined('SushiMcp::Tools::FindFiles')
      register_if_defined('SushiMcp::Tools::ListSushiApps')
      register_if_defined('SushiMcp::Tools::SkillsList')
      register_if_defined('SushiMcp::Tools::SkillsGet')
      register_if_defined('SushiMcp::Tools::SkillsSearch')
      register_if_defined('SushiMcp::Tools::GetAppStructure')
      register_if_defined('SushiMcp::Tools::GetAppTemplate')
      register_if_defined('SushiMcp::Tools::CompareApps')
    end

    def register_if_defined(class_name)
      klass = Object.const_get(class_name)
      register(klass.new(@safety))
    rescue NameError
      # Class not defined yet (file might not exist), ignore
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

