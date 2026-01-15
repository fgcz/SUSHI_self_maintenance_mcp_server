require 'yaml'
require 'pathname'

module SushiMcp
  class Safety
    CONFIG_PATH = File.expand_path('../../config/safety.yml', __dir__)

    def initialize
      @config = load_config
      @safe_root = File.expand_path(@config['safe_root'] || File.expand_path('../../..', __FILE__))
      @allowed_paths = @config['allowed_paths'] || []
      @blocklist = @config['blocklist'] || []
      @limits = @config['limits'] || {}
    end

    def validate_path(path)
      absolute_path = File.expand_path(path, @safe_root)
      
      # 1. Check if path is within SAFE_ROOT
      unless inside_safe_root?(absolute_path)
        raise "Access denied: Path is outside safe root (#{@safe_root})"
      end

      # 2. Check blocklist
      if blocked?(absolute_path)
        raise "Access denied: File matches blocklist pattern"
      end

      absolute_path
    end

    def max_read_bytes
      @limits['max_read_bytes'] || 100_000
    end

    def max_search_lines
      @limits['max_search_lines'] || 500
    end

    def max_tree_depth
      @limits['max_tree_depth'] || 5
    end

    private

    def load_config
      if File.exist?(CONFIG_PATH)
        YAML.load_file(CONFIG_PATH)
      else
        {}
      end
    end

    def inside_safe_root?(path)
      path.start_with?(@safe_root)
    end

    def blocked?(path)
      filename = File.basename(path)
      @blocklist.any? do |pattern|
        File.fnmatch?(pattern, filename, File::FNM_DOTMATCH)
      end
    end
  end
end
