#!/usr/bin/env ruby
# encoding: utf-8
# Get SUSHI App Template - Generate a template for creating a new SUSHI App
#
# Usage:
#   ruby get_app_template.rb [new_app_name] [base_app] [category] [lib_path]
#
# Examples:
#   ruby get_app_template.rb MyNewApp                    # Generic template
#   ruby get_app_template.rb MyNewApp FastqcApp          # Based on FastqcApp
#   ruby get_app_template.rb MyNewApp FastqcApp "QC"     # With category

require_relative 'app_parser'

def generate_generic_template(class_name, app_name, ezrun_name, category)
  <<~TEMPLATE
    #!/usr/bin/env ruby
    # encoding: utf-8

    require 'sushi_fabric'
    require_relative 'global_variables'
    include GlobalVariables

    class #{class_name} < SushiFabric::SushiApp
      def initialize
        super
        @name = '#{app_name}'
        @params['process_mode'] = 'DATASET'  # or 'SAMPLE' for per-sample processing
        @analysis_category = '#{category}'
        @description = <<-EOS
    Description of what this app does.<br/>
    Add links to documentation if available.
    EOS

        # Required input columns from dataset
        @required_columns = ['Name', 'Read1']
        
        # Required parameters that must be set
        @required_params = ['name']

        # Computational resources
        @params['cores'] = [8, 1, 2, 4, 8, 16]
        @params['cores', 'context'] = 'slurm'
        @params['ram'] = [30, 15, 62]
        @params['ram', 'description'] = 'GB'
        @params['ram', 'context'] = 'slurm'
        @params['scratch'] = [100, 50, 200]
        @params['scratch', 'description'] = 'GB'
        @params['scratch', 'context'] = 'slurm'

        # App-specific parameters
        @params['name'] = '#{app_name}_Result'
        @params['mail'] = ''

        # Environment modules to load
        @modules = ['Dev/R']

        # Columns/tags to inherit from input dataset
        @inherit_columns = ['Order Id']
        @inherit_tags = ['Factor', 'B-Fabric']
      end

      def set_default_parameters
        # Set defaults based on input dataset
        # Example: @params['paired'] = dataset_has_column?('Read2')
      end

      def preprocess
        # Modify state before job submission
        # Example: add Read2 to required columns if paired
      end

      def next_dataset
        # Define output dataset structure
        report_dir = File.join(@result_dir, @params['name'])
        {
          'Name' => @params['name'],
          'Report [Link]' => File.join(report_dir, '00index.html'),
          'Result [File]' => report_dir
        }.merge(extract_columns(colnames: @inherit_columns))
      end

      def commands
        # Return the R command to execute
        run_RApp('#{ezrun_name}')
      end
    end

    # For CLI testing:
    if __FILE__ == $0
      usecase = #{class_name}.new
      usecase.project = 'p1001'
      usecase.user = 'developer'
      usecase.dataset_tsv_file = 'input_dataset.tsv'
      # usecase.run
    end
  TEMPLATE
end

def generate_template_from_structure(class_name, app_name, ezrun_name, base)
  modules_str = base.modules.empty? ? "['Dev/R']" : base.modules.map { |m| "'#{m}'" }.join(', ')
  req_cols_str = base.required_columns.map { |c| "'#{c}'" }.join(', ')
  req_params_str = base.required_params.map { |p| "'#{p}'" }.join(', ')
  inherit_cols_str = base.inherit_columns.map { |c| "'#{c}'" }.join(', ')

  <<~TEMPLATE
    #!/usr/bin/env ruby
    # encoding: utf-8
    # Based on: #{base.class_name}

    require 'sushi_fabric'
    require_relative 'global_variables'
    include GlobalVariables

    class #{class_name} < SushiFabric::SushiApp
      def initialize
        super
        @name = '#{app_name}'
        @params['process_mode'] = '#{base.process_mode || 'DATASET'}'
        @analysis_category = '#{base.analysis_category || 'Other'}'
        @description = <<-EOS
    TODO: Add description for #{app_name}
    Based on #{base.class_name}: #{base.description&.lines&.first&.strip || 'N/A'}
    EOS

        @required_columns = [#{req_cols_str}]
        @required_params = [#{req_params_str}]

        # Computational resources (from #{base.class_name})
        @params['cores'] = #{base.params['cores'] || '[8, 1, 2, 4, 8]'}
        @params['cores', 'context'] = 'slurm'
        @params['ram'] = #{base.params['ram'] || '[30, 15, 62]'}
        @params['ram', 'description'] = 'GB'
        @params['ram', 'context'] = 'slurm'
        @params['scratch'] = #{base.params['scratch'] || '[100, 50, 200]'}
        @params['scratch', 'description'] = 'GB'
        @params['scratch', 'context'] = 'slurm'

        @params['name'] = '#{app_name}_Result'
        @params['mail'] = ''

        @modules = [#{modules_str}]
        @inherit_columns = [#{inherit_cols_str}]
      end

      def set_default_parameters
        # TODO: Implement based on your needs
      end

      def preprocess
        # TODO: Implement if needed
      end

      def next_dataset
        report_dir = File.join(@result_dir, @params['name'])
        {
          'Name' => @params['name'],
          'Report [Link]' => File.join(report_dir, '00index.html'),
          'Result [File]' => report_dir
        }.merge(extract_columns(colnames: @inherit_columns))
      end

      def commands
        run_RApp('#{ezrun_name}')
      end
    end

    if __FILE__ == $0
      usecase = #{class_name}.new
      usecase.project = 'p1001'
      usecase.user = 'developer'
      usecase.dataset_tsv_file = 'input_dataset.tsv'
      # usecase.run
    end
  TEMPLATE
end

# CLI interface
if __FILE__ == $0
  new_app_name = ARGV[0] || 'NewApp'
  base_app = ARGV[1]
  category = ARGV[2] || 'Other'
  lib_path = ARGV[3] || SushiAppParser::DEFAULT_LIB_PATH
  
  # Normalize app name
  new_app_name = new_app_name.gsub(/App$/i, '')
  class_name = "#{new_app_name}App"
  ezrun_name = "EzApp#{new_app_name}"

  if base_app
    parser = SushiAppParser.new(lib_path)
    structure = parser.parse_app(base_app)
    
    if structure.nil?
      puts "# Base app '#{base_app}' not found. Generating generic template instead.\n\n"
      puts generate_generic_template(class_name, new_app_name, ezrun_name, category)
    else
      puts generate_template_from_structure(class_name, new_app_name, ezrun_name, structure)
    end
  else
    puts generate_generic_template(class_name, new_app_name, ezrun_name, category)
  end
end
