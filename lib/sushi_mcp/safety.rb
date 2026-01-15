require 'yaml'
require 'pathname'

module SushiMcp
  class Safety
    CONFIG_PATH = File.expand_path('../../config/safety.yml', __dir__)
    SERVER_ROOT = File.expand_path('../..', __dir__)

    attr_reader :workspace_root

    def initialize
      @config = load_config
      @default_root = File.expand_path(@config['safe_root'] || SERVER_ROOT)
      @workspace_root = nil  # Set dynamically via set_workspace
      @allowed_paths = @config['allowed_paths'] || []
      @blocklist = @config['blocklist'] || []
      @limits = @config['limits'] || {}
    end

    # Set workspace root from MCP client (roots) or environment
    def set_workspace(roots = nil)
      # Priority:
      # 1. MCP client roots (from initialize params)
      # 2. Environment variable SUSHI_WORKSPACE
      # 3. Default safe_root from config
      
      if roots && roots.is_a?(Array) && !roots.empty?
        # MCP roots format: [{"uri": "file:///path/to/workspace", "name": "..."}]
        root = roots.first
        if root.is_a?(Hash) && root['uri']
          uri = root['uri']
          @workspace_root = uri.sub(/^file:\/\//, '')
        elsif root.is_a?(String)
          @workspace_root = root.sub(/^file:\/\//, '')
        end
      end

      @workspace_root ||= ENV['SUSHI_WORKSPACE']
      @workspace_root ||= @default_root

      $stderr.puts "[INFO] Workspace root set to: #{@workspace_root}"
      @workspace_root
    end

    def safe_root
      @workspace_root || @default_root
    end

    def validate_path(path)
      absolute_path = File.expand_path(path, safe_root)
      
      # 1. Check if path is within safe_root
      unless inside_safe_root?(absolute_path)
        raise "Access denied: Path is outside safe root (#{safe_root})"
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

    # Find the first existing SUSHI lib path
    def sushi_lib_path
      candidates = @config['sushi_lib_paths'] || ['master/lib', 'sushi/master/lib', 'lib']
      
      candidates.each do |candidate|
        full_path = File.join(safe_root, candidate)
        if File.directory?(full_path)
          return full_path
        end
      end
      
      # Return the first candidate even if it doesn't exist (for error messages)
      File.join(safe_root, candidates.first)
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
      path.start_with?(safe_root)
    end

    def blocked?(path)
      filename = File.basename(path)
      @blocklist.any? do |pattern|
        File.fnmatch?(pattern, filename, File::FNM_DOTMATCH)
      end
    end
  end
end
