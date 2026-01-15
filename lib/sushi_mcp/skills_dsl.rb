require_relative 'skill_contexts'

module SushiMcp
  class SkillsDsl
    # Extended Skill Struct with version, inputs, effects, evolution_rules
    Skill = Struct.new(
      :id,
      :version,           # NEW: Skill version string
      :title,
      :use_when,
      :inputs,            # NEW: Array of input symbols
      :requires,
      :guarantees,        # CHANGED: Can be symbol or array of symbols
      :depends_on,
      :content,
      :behavior,
      :effects,           # NEW: Hash of EffectContext
      :evolution_rules,   # NEW: EvolveContext
      :created_at,        # NEW: Creation timestamp
      keyword_init: true
    ) do
      # Check if a field can be evolved based on evolution_rules
      def can_evolve?(field)
        return true unless evolution_rules
        evolution_rules.can_evolve?(field)
      end

      # Get history from VersionManager (if available)
      def history
        return [] unless defined?(VersionManager)
        VersionManager.list_versions.select { |v| v[:filename].include?(id.to_s) }
      end
    end
    
    def self.load(path)
      dsl = new
      dsl.instance_eval(File.read(path), path)
      dsl.skills
    end
    
    def initialize
      @skills = []
    end
    
    attr_reader :skills
    
    def skill(id, &block)
      builder = SkillBuilder.new(id)
      builder.instance_eval(&block)
      @skills << builder.build
    end
  end
  
  class SkillBuilder
    def initialize(id)
      @id = id
      @data = { created_at: Time.now }
    end

    # NEW: Version declaration
    def version(value)
      @data[:version] = value
    end

    def title(value)
      @data[:title] = value
    end

    def use_when(value)
      @data[:use_when] = value
    end

    # NEW: Explicit inputs declaration
    def inputs(*args)
      @data[:inputs] = args.flatten
    end

    def requires(value)
      @data[:requires] = value
    end

    # ENHANCED: Supports both single value and block form
    def guarantees(value = nil, &block)
      if block_given?
        ctx = GuaranteesContext.new
        ctx.instance_eval(&block)
        @data[:guarantees] = ctx.guarantees
      else
        @data[:guarantees] = value
      end
    end

    def depends_on(value)
      @data[:depends_on] = value
    end

    def content(value)
      @data[:content] = value
    end

    def behavior(&block)
      @data[:behavior] = block
    end

    # NEW: Named side-effect context
    def effect(name, &block)
      @data[:effects] ||= {}
      ctx = EffectContext.new(name)
      ctx.instance_eval(&block) if block_given?
      @data[:effects][name] = ctx
    end

    # NEW: Self-evolution rules
    def evolve(&block)
      ctx = EvolveContext.new(@id)
      ctx.instance_eval(&block) if block_given?
      @data[:evolution_rules] = ctx
    end

    def build
      SkillsDsl::Skill.new(id: @id, **@data)
    end
  end
end
