#!/usr/bin/env ruby
# encoding: utf-8
# Compare SUSHI Apps - Compare two SUSHI Apps to see their differences
#
# Usage:
#   ruby compare_apps.rb <app1> <app2> [lib_path]
#
# Examples:
#   ruby compare_apps.rb FastqcApp Fastqc2App
#   ruby compare_apps.rb STARApp BowtieApp /srv/sushi/production/master/lib

require_relative 'app_parser'

def format_comparison(c, parser)
  app1 = parser.parse_app(c[:app1])
  app2 = parser.parse_app(c[:app2])
  diff = c[:differences]

  output = <<~OUTPUT
    # Comparison: #{c[:app1]} vs #{c[:app2]}

    ## Basic Info
    | Property | #{c[:app1]} | #{c[:app2]} |
    |----------|-------------|-------------|
    | Name | #{app1.name} | #{app2.name} |
    | Category | #{diff[:analysis_category][0] || 'N/A'} | #{diff[:analysis_category][1] || 'N/A'} |
    | Process Mode | #{diff[:process_mode][0] || 'N/A'} | #{diff[:process_mode][1] || 'N/A'} |
    | ezRun App | #{app1.ezrun_app || 'N/A'} | #{app2.ezrun_app || 'N/A'} |

    ## Required Columns
  OUTPUT

  rc = diff[:required_columns]
  if rc[:only_in_app1].empty? && rc[:only_in_app2].empty?
    output += "Both apps have identical required columns: #{rc[:common].join(', ')}\n"
  else
    output += "- **Common**: #{rc[:common].empty? ? 'None' : rc[:common].join(', ')}\n"
    output += "- **Only in #{c[:app1]}**: #{rc[:only_in_app1].empty? ? 'None' : rc[:only_in_app1].join(', ')}\n"
    output += "- **Only in #{c[:app2]}**: #{rc[:only_in_app2].empty? ? 'None' : rc[:only_in_app2].join(', ')}\n"
  end

  output += "\n## Modules\n"
  mod = diff[:modules]
  if mod[:only_in_app1].empty? && mod[:only_in_app2].empty?
    output += "Both apps use identical modules: #{mod[:common].join(', ')}\n"
  else
    output += "- **Common**: #{mod[:common].empty? ? 'None' : mod[:common].join(', ')}\n"
    output += "- **Only in #{c[:app1]}**: #{mod[:only_in_app1].empty? ? 'None' : mod[:only_in_app1].join(', ')}\n"
    output += "- **Only in #{c[:app2]}**: #{mod[:only_in_app2].empty? ? 'None' : mod[:only_in_app2].join(', ')}\n"
  end

  output += "\n## Parameters\n"
  params = diff[:params]
  if params[:only_in_app1].empty? && params[:only_in_app2].empty?
    output += "Both apps have the same parameter keys.\n"
  else
    output += "- **Common**: #{params[:common].size} parameters\n"
    output += "- **Only in #{c[:app1]}**: #{params[:only_in_app1].empty? ? 'None' : params[:only_in_app1].join(', ')}\n"
    output += "- **Only in #{c[:app2]}**: #{params[:only_in_app2].empty? ? 'None' : params[:only_in_app2].join(', ')}\n"
  end

  output += "\n## Methods\n"
  methods = diff[:methods]
  if methods[:only_in_app1].empty? && methods[:only_in_app2].empty?
    output += "Both apps define the same methods: #{methods[:common].join(', ')}\n"
  else
    output += "- **Common**: #{methods[:common].join(', ')}\n"
    output += "- **Only in #{c[:app1]}**: #{methods[:only_in_app1].empty? ? 'None' : methods[:only_in_app1].join(', ')}\n"
    output += "- **Only in #{c[:app2]}**: #{methods[:only_in_app2].empty? ? 'None' : methods[:only_in_app2].join(', ')}\n"
  end

  output
end

# CLI interface
if __FILE__ == $0
  app1_name = ARGV[0]
  app2_name = ARGV[1]
  lib_path = ARGV[2] || SushiAppParser::DEFAULT_LIB_PATH
  
  unless app1_name && app2_name
    puts "Usage: ruby compare_apps.rb <app1> <app2> [lib_path]"
    puts ""
    puts "Examples:"
    puts "  ruby compare_apps.rb FastqcApp Fastqc2App"
    puts "  ruby compare_apps.rb STARApp BowtieApp /srv/sushi/production/master/lib"
    exit 1
  end

  parser = SushiAppParser.new(lib_path)
  comparison = parser.compare_apps(app1_name, app2_name)

  if comparison.nil?
    app1_exists = parser.parse_app(app1_name)
    app2_exists = parser.parse_app(app2_name)
    
    errors = []
    errors << "'#{app1_name}' not found" unless app1_exists
    errors << "'#{app2_name}' not found" unless app2_exists
    
    puts "Error: #{errors.join(' and ')}"
    exit 1
  end

  puts format_comparison(comparison, parser)
end
