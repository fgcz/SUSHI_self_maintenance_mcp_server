require_relative 'skills_config'
require_relative 'version_manager'
require_relative 'action_log'
require_relative 'skills_dsl'

module SushiMcp
  class SafeEvolver
    class EvolutionError < StandardError; end
    
    DSL_PATH = File.expand_path('../../skills/sushi.rb', __dir__)
    
    # Session counter for evolution limits
    @@evolution_count = 0
    
    def self.reset_session!
      @@evolution_count = 0
    end
    
    def self.propose(skill_id:, new_definition:)
      # 1. Check if evolution is enabled
      unless SkillsConfig.evolution_enabled?
        return { success: false, error: "Evolution is disabled. Set 'evolution_enabled: true' in config." }
      end
      
      # 2. Check immutable skills
      immutable = SkillsConfig.load['immutable_skills'] || []
      if immutable.include?(skill_id.to_s)
        return { success: false, error: "Skill '#{skill_id}' is immutable and cannot be modified." }
      end
      
      # 3. Check evolution count limit
      max_evolutions = SkillsConfig.load['max_evolutions_per_session'] || 3
      if @@evolution_count >= max_evolutions
        return { success: false, error: "Evolution limit reached (#{max_evolutions}/session). Reset required." }
      end
      
      # 4. Validate syntax in sandbox
      validation = validate_in_sandbox(new_definition)
      return validation unless validation[:success]
      
      # 5. Generate preview
      { 
        success: true, 
        preview: new_definition,
        message: "Proposal validated. Use 'apply' command with approved=true to apply."
      }
    end
    
    def self.apply(skill_id:, new_definition:, approved: false)
      config = SkillsConfig.load
      
      # Check approval requirement
      if config['require_human_approval'] && !approved
        return { 
          success: false, 
          error: "Human approval required. Set approved=true to confirm.",
          pending: true 
        }
      end
      
      # Re-validate before apply
      unless SkillsConfig.evolution_enabled?
        return { success: false, error: "Evolution is disabled." }
      end
      
      validation = validate_in_sandbox(new_definition)
      return validation unless validation[:success]
      
      # Create snapshot before modification
      snapshot = VersionManager.create_snapshot(reason: "before evolving #{skill_id}")
      
      begin
        # Apply the change
        apply_change(skill_id, new_definition)
        
        # Increment evolution counter
        @@evolution_count += 1
        
        # Log the action
        ActionLog.record(
          action: 'skill_evolved',
          skill_id: skill_id,
          details: { 
            new_definition: new_definition[0, 500],  # Truncate for log
            snapshot: snapshot,
            evolution_count: @@evolution_count
          }
        )
        
        { success: true, message: "Skill '#{skill_id}' evolved successfully. Snapshot: #{snapshot}" }
      rescue => e
        # Rollback on error
        VersionManager.rollback(snapshot)
        { success: false, error: "Evolution failed and rolled back: #{e.message}" }
      end
    end
    
    def self.add_skill(skill_id:, definition:, approved: false)
      config = SkillsConfig.load
      
      if config['require_human_approval'] && !approved
        return { success: false, error: "Human approval required.", pending: true }
      end
      
      unless SkillsConfig.evolution_enabled?
        return { success: false, error: "Evolution is disabled." }
      end
      
      # Validate the new skill definition
      full_definition = "skill :#{skill_id} do\n#{definition}\nend"
      validation = validate_in_sandbox(full_definition)
      return validation unless validation[:success]
      
      # Create snapshot
      snapshot = VersionManager.create_snapshot(reason: "before adding #{skill_id}")
      
      begin
        # Append to file
        File.open(DSL_PATH, 'a') do |f|
          f.puts "\n#{full_definition}"
        end
        
        @@evolution_count += 1
        
        ActionLog.record(
          action: 'skill_added',
          skill_id: skill_id,
          details: { snapshot: snapshot }
        )
        
        { success: true, message: "Skill '#{skill_id}' added successfully." }
      rescue => e
        VersionManager.rollback(snapshot)
        { success: false, error: "Failed to add skill: #{e.message}" }
      end
    end
    
    private
    
    def self.validate_in_sandbox(definition)
      begin
        # Parse to check syntax
        RubyVM::AbstractSyntaxTree.parse(definition)
        
        # Try to evaluate in isolated context
        test_dsl = SkillsDsl.new
        test_dsl.instance_eval(definition)
        
        { success: true }
      rescue SyntaxError => e
        { success: false, error: "Syntax error: #{e.message}" }
      rescue StandardError => e
        { success: false, error: "Validation error: #{e.message}" }
      end
    end
    
    def self.apply_change(skill_id, new_definition)
      content = File.read(DSL_PATH)
      
      # Pattern to match existing skill block
      # This is a simplified approach - for complex cases, AST manipulation would be better
      pattern = /skill\s+:#{skill_id}\s+do.*?^end/m
      
      if content.match?(pattern)
        # Replace existing skill
        new_content = content.gsub(pattern, new_definition)
        File.write(DSL_PATH, new_content)
      else
        # Skill doesn't exist - append
        File.open(DSL_PATH, 'a') do |f|
          f.puts "\n#{new_definition}"
        end
      end
    end
  end
end
