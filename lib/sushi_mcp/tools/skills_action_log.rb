require_relative 'base_tool'
require_relative '../action_log'

module SushiMcp
  module Tools
    class SkillsActionLog < BaseTool
      def name
        'skills_action_log'
      end

      def description
        'View or clear the action log (self-reference). This allows the LLM to understand what it has done previously.'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            command: {
              type: 'string',
              description: 'Command to execute: "view" or "clear" (default: "view")',
              enum: ['view', 'clear']
            },
            limit: {
              type: 'integer',
              description: 'Number of recent log entries to retrieve (default: 50)'
            }
          }
        }
      end

      def call(arguments)
        command = arguments['command'] || 'view'
        limit = arguments['limit'] || 50

        case command
        when 'view'
          history = ActionLog.history(limit: limit)
          if history.empty?
            return text_content("Action log is empty.")
          end
          
          output = "Recent Action Log (Last #{history.size} entries):\n\n"
          history.each do |entry|
            output += "- [#{entry['timestamp']}] #{entry['action']}"
            output += " (Skill: #{entry['skill_id']})" if entry['skill_id']
            output += "\n"
            if entry['details'] && !entry['details'].empty?
              details_str = entry['details'].to_s
              # Truncate if too long
              details_str = details_str[0, 200] + "..." if details_str.length > 200
              output += "  Details: #{details_str}\n"
            end
          end
          text_content(output)
          
        when 'clear'
          ActionLog.clear!
          text_content("Action log cleared.")
          
        else
          text_content("Unknown command: #{command}")
        end
      end
    end
  end
end
