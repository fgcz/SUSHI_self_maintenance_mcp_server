require_relative 'base_tool'
require_relative '../skills_config'

module SushiMcp
  module Tools
    class SkillsConfigTool < BaseTool
      def name
        'skills_config'
      end

      def description
        'View or modify Skills DSL configuration. Use to enable/disable features or check current settings.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            command: {
              type: 'string',
              description: 'Command: "view", "set", or "emergency_disable"',
              enum: ['view', 'set', 'emergency_disable']
            },
            key: {
              type: 'string',
              description: 'Config key to set (for "set" command)'
            },
            value: {
              type: 'string',
              description: 'Value to set (for "set" command). Use "true"/"false" for booleans.'
            }
          }
        }
      end

      def call(arguments)
        command = arguments['command'] || 'view'

        case command
        when 'view'
          config = SkillsConfig.load
          output = "Current Skills Configuration:\n\n"
          output += "```yaml\n#{config.to_yaml}```\n\n"
          output += "Status:\n"
          output += "- Skills DSL: #{config['enabled'] ? 'ENABLED' : 'DISABLED'}\n"
          output += "- Evolution: #{config['evolution_enabled'] ? 'ENABLED' : 'DISABLED'}\n"
          output += "- Human Approval Required: #{config['require_human_approval'] ? 'YES' : 'NO'}\n"
          text_content(output)

        when 'set'
          key = arguments['key']
          value = arguments['value']
          
          return text_content("Error: key and value are required for 'set' command") unless key && value

          config = SkillsConfig.load
          
          # Convert string values to appropriate types
          converted_value = case value.downcase
                           when 'true' then true
                           when 'false' then false
                           else
                             # Try to convert to integer, otherwise keep as string
                             Integer(value) rescue value
                           end
          
          config[key] = converted_value
          SkillsConfig.save(config)
          
          text_content("Configuration updated: #{key} = #{converted_value}")

        when 'emergency_disable'
          SkillsConfig.disable!
          text_content("EMERGENCY DISABLE: Skills DSL has been disabled. All evolution features are now OFF.")

        else
          text_content("Unknown command: #{command}")
        end
      end
    end
  end
end
