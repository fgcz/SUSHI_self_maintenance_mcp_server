module SushiMcp
  class SkillsDsl
    Skill = Struct.new(
      :id, :title, :use_when, :requires, :guarantees, 
      :depends_on, :content, :behavior, keyword_init: true
    )
    
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
      @data = {}
    end

    def title(value)
      @data[:title] = value
    end

    def use_when(value)
      @data[:use_when] = value
    end

    def requires(value)
      @data[:requires] = value
    end

    def guarantees(value)
      @data[:guarantees] = value
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

    def build
      SkillsDsl::Skill.new(id: @id, **@data)
    end
  end
end
