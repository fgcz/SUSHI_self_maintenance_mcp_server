#!/usr/bin/env ruby
# encoding: utf-8
# Get SUSHI App Structure - Analyze and display the structure of a SUSHI App
#
# Usage:
#   ruby get_app_structure.rb <app_name> [lib_path]
#
# Examples:
#   ruby get_app_structure.rb FastqcApp
#   ruby get_app_structure.rb Fastqc /srv/sushi/production/master/lib

require_relative 'app_parser'

def format_structure(s)
  output = <<~OUTPUT
    # #{s.class_name} Structure Analysis

    ## Basic Info
    - **Name**: #{s.name || 'N/A'}
    - **Category**: #{s.analysis_category || 'N/A'}
    - **Process Mode**: #{s.process_mode || 'N/A'}
    - **ezRun App**: #{s.ezrun_app || 'N/A'}
    - **File**: #{s.file_path}

    ## Description
    #{s.description || 'No description'}

    ## Required Columns
    #{s.required_columns.empty? ? 'None' : s.required_columns.map { |c| "- #{c}" }.join("\n")}

    ## Required Parameters
    #{s.required_params.empty? ? 'None' : s.required_params.map { |p| "- #{p}" }.join("\n")}

    ## Parameters
  OUTPUT

  if s.params.empty?
    output += "No parameters defined\n"
  else
    s.params.each do |key, value|
      output += "- **#{key}**: #{value}\n"
    end
  end

  output += <<~OUTPUT

    ## Modules
    #{s.modules.empty? ? 'None' : s.modules.map { |m| "- #{m}" }.join("\n")}

    ## Inherited Columns
    #{s.inherit_columns.empty? ? 'None' : s.inherit_columns.map { |c| "- #{c}" }.join("\n")}

    ## Inherited Tags
    #{s.inherit_tags.empty? ? 'None' : s.inherit_tags.map { |t| "- #{t}" }.join("\n")}

    ## Methods
    #{s.methods.map { |m| "- #{m}" }.join("\n")}
  OUTPUT

  output
end

# CLI interface
if __FILE__ == $0
  app_name = ARGV[0]
  lib_path = ARGV[1] || SushiAppParser::DEFAULT_LIB_PATH
  
  unless app_name
    puts "Usage: ruby get_app_structure.rb <app_name> [lib_path]"
    puts ""
    puts "Examples:"
    puts "  ruby get_app_structure.rb FastqcApp"
    puts "  ruby get_app_structure.rb Fastqc /srv/sushi/production/master/lib"
    exit 1
  end

  parser = SushiAppParser.new(lib_path)
  structure = parser.parse_app(app_name)

  if structure.nil?
    available = parser.list_apps.first(20).join(', ')
    puts "App '#{app_name}' not found."
    puts ""
    puts "Available apps (first 20): #{available}"
    puts ""
    puts "Use list_sushi_apps.rb to see all apps."
    exit 1
  end

  puts format_structure(structure)
end
