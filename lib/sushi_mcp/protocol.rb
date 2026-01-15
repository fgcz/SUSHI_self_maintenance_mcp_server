require 'json'
require_relative 'tool_registry'

module SushiMcp
  class Protocol
    PROTOCOL_VERSION = '2024-11-05'

    def initialize
      @tool_registry = ToolRegistry.new
      @initialized = false
    end

    def handle_message(line)
      request = parse_json(line)
      return nil unless request

      id = request['id']
      method = request['method']
      params = request['params'] || {}

      result = case method
               when 'initialize'
                 handle_initialize(params)
               when 'initialized'
                 # No response needed for initialized notification
                 return nil
               when 'tools/list'
                 handle_tools_list
               when 'tools/call'
                 handle_tools_call(params)
               else
                 # Ignore unknown methods or notifications
                 return nil
               end

      format_response(id, result)
    rescue StandardError => e
      format_error(id, -32603, "Internal error: #{e.message}")
    end

    private

    def parse_json(line)
      JSON.parse(line)
    rescue JSON::ParserError
      nil
    end

    def handle_initialize(params)
      # Extract workspace roots from client
      roots = params['roots'] || params['workspaceFolders']
      
      # Set workspace in Safety module
      @tool_registry.set_workspace(roots)
      @initialized = true

      {
        protocolVersion: PROTOCOL_VERSION,
        capabilities: {
          tools: {}
        },
        serverInfo: {
          name: 'sushi-mcp-server',
          version: SushiMcp::VERSION
        }
      }
    end

    def handle_tools_list
      {
        tools: @tool_registry.list_tools
      }
    end

    def handle_tools_call(params)
      name = params['name']
      arguments = params['arguments'] || {}
      
      content = @tool_registry.call_tool(name, arguments)
      
      {
        content: content
      }
    end

    def format_response(id, result)
      {
        jsonrpc: '2.0',
        id: id,
        result: result
      }
    end

    def format_error(id, code, message)
      {
        jsonrpc: '2.0',
        id: id,
        error: {
          code: code,
          message: message
        }
      }
    end
  end
end

