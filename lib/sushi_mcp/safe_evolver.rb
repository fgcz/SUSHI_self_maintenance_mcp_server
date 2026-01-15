require_relative 'skills_config'
require_relative 'version_manager'
require_relative 'action_log'
require_relative 'skills_dsl'
require_relative 'kairos'

module SushiMcp
  class SafeEvolver
    class EvolutionError < StandardError; end
    
    DSL_PATH = File.expand_path('../../skills/sushi.rb', __dir__)
    
    # Session counter for evolution limits
    @@evolution_count = 0
    
    def self.reset_session!
      @@evolution_count = 0
    end

    def self.evolution_count
      @@evolution_count
    end
    
    # Propose a change to a specific field of a skill
    # Integrates with evolve DSL rules
    def self.propose_field(skill_id:, field:, new_value:)
      # 1. Check if evolution is enabled
      unless SkillsConfig.evolution_enabled?
        return { success: false, error: "Evolution is disabled. Set 'evolution_enabled: true' in config." }
      end
      
      # 2. Find the skill
      skill = Kairos.skill(skill_id)
      unless skill
        return { success: false, error: "Skill '#{skill_id}' not found." }
      end
      
      # 3. Check skill's evolution rules
      rules = skill.evolution_rules
      if rules
        if rules.denied.include?(field.to_sym)
          return { success: false, error: "Field '#{field}' is denied for evolution by skill rules." }
        end
        
        unless rules.allowed.empty? || rules.allowed.include?(field.to_sym)
          return { success: false, error: "Field '#{field}' is not in the allowed list for evolution." }
        end
      end
      
      # 4. Check immutable skills from config
      immutable = SkillsConfig.load['immutable_skills'] || []
      if immutable.include?(skill_id.to_s)
        return { success: false, error: "Skill '#{skill_id}' is marked as immutable in config." }
      end
      
      # 5. Check evolution count limit
      max_evolutions = SkillsConfig.load['max_evolutions_per_session'] || 3
      if @@evolution_count >= max_evolutions
        return { success: false, error: "Evolution limit reached (#{max_evolutions}/session). Reset required." }
      end
      
      { 
        success: true, 
        skill_id: skill_id,
        field: field,
        current_value: skill.send(field),
        proposed_value: new_value,
        message: "Proposal validated. Use 'apply_field' with approved=true to apply."
      }
    end
    
    def self.propose(skill_id:, new_definition:)
      # 1. Check if evolution is enabled
      unless SkillsConfig.evolution_enabled?
        return { success: false, error: "Evolution is disabled. Set 'evolution_enabled: true' in config." }
      end
      
      # 2. Check skill's evolution rules (if skill exists)
      skill = Kairos.skill(skill_id)
      if skill && skill.evolution_rules
        rules = skill.evolution_rules
        # If skill has evolution rules with all fields denied, block
        if rules.denied.include?(:all) || (rules.denied.include?(:behavior) && rules.denied.include?(:content))
          return { success: false, error: "Skill '#{skill_id}' has evolution rules that deny modification." }
        end
      end
      
      # 3. Check immutable skills from config
      immutable = SkillsConfig.load['immutable_skills'] || []
      if immutable.include?(skill_id.to_s)
        return { success: false, error: "Skill '#{skill_id}' is immutable and cannot be modified." }
      end
      
      # 4. Check evolution count limit
      max_evolutions = SkillsConfig.load['max_evolutions_per_session'] || 3
      if @@evolution_count >= max_evolutions
        return { success: false, error: "Evolution limit reached (#{max_evolutions}/session). Reset required." }
      end
      
      # 5. Validate syntax in sandbox
      validation = validate_in_sandbox(new_definition)
      return validation unless validation[:success]
      
      # 6. Generate preview
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
      
      # Check skill's evolution rules again
      skill = Kairos.skill(skill_id)
      if skill && skill.evolution_rules
        rules = skill.evolution_rules
        if rules.denied.include?(:all)
          return { success: false, error: "Skill '#{skill_id}' denies all evolution." }
        end
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
        
        # Reload Kairos to pick up changes
        Kairos.reload!
        
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
        Kairos.reload!
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
      
      # Check if skill already exists
      if Kairos.skill(skill_id)
        return { success: false, error: "Skill '#{skill_id}' already exists. Use 'propose' to modify." }
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
        
        # Reload Kairos to pick up new skill
        Kairos.reload!
        
        ActionLog.record(
          action: 'skill_added',
          skill_id: skill_id,
          details: { snapshot: snapshot }
        )
        
        { success: true, message: "Skill '#{skill_id}' added successfully." }
      rescue => e
        VersionManager.rollback(snapshot)
        Kairos.reload!
        { success: false, error: "Failed to add skill: #{e.message}" }
      end
    end
    
    # Check if a skill can evolve a specific field
    def self.can_evolve?(skill_id, field)
      skill = Kairos.skill(skill_id)
      return false unless skill
      
      # Check config immutable list
      immutable = SkillsConfig.load['immutable_skills'] || []
      return false if immutable.include?(skill_id.to_s)
      
      # Check skill's evolution rules
      skill.can_evolve?(field)
    end
    
    # Get evolution status for a skill
    def self.evolution_status(skill_id)
      skill = Kairos.skill(skill_id)
      return { error: "Skill not found" } unless skill
      
      rules = skill.evolution_rules
      immutable_config = SkillsConfig.load['immutable_skills'] || []
      
      {
        skill_id: skill_id,
        version: skill.version,
        config_immutable: immutable_config.include?(skill_id.to_s),
        has_evolution_rules: !rules.nil?,
        allowed_fields: rules&.allowed || [],
        denied_fields: rules&.denied || [],
        evolution_enabled: SkillsConfig.evolution_enabled?,
        session_evolution_count: @@evolution_count,
        max_evolutions: SkillsConfig.load['max_evolutions_per_session'] || 3
      }
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
