#!/usr/bin/env ruby
# encoding: utf-8
# SUSHI App Parser - Standalone library for parsing SUSHI App files
#
# Usage:
#   require_relative 'app_parser'
#   parser = SushiAppParser.new('/srv/sushi/production/master/lib')
#   structure = parser.parse_app('FastqcApp')
#
# Or run directly:
#   ruby app_parser.rb /path/to/sushi/lib FastqcApp

class SushiAppParser
  AppStructure = Struct.new(
    :name,
    :class_name,
    :file_path,
    :analysis_category,
    :description,
    :process_mode,
    :required_columns,
    :required_params,
    :params,
    :modules,
    :inherit_columns,
    :inherit_tags,
    :ezrun_app,
    :methods,
    keyword_init: true
  )

  DEFAULT_LIB_PATH = '/srv/sushi/production/master/lib'

  def initialize(lib_path = nil)
    @lib_path = lib_path || DEFAULT_LIB_PATH
  end

  def parse_app(app_name)
    # Normalize app name (add "App" suffix if not present)
    class_name = app_name.end_with?('App') ? app_name : "#{app_name}App"
    file_name = "#{class_name}.rb"
    file_path = File.join(@lib_path, file_name)

    unless File.exist?(file_path)
      return nil
    end

    content = File.read(file_path)
    parse_content(content, class_name, file_path)
  end

  def parse_content(content, class_name, file_path)
    structure = AppStructure.new(
      class_name: class_name,
      file_path: file_path,
      params: {},
      required_columns: [],
      required_params: [],
      modules: [],
      inherit_columns: [],
      inherit_tags: [],
      methods: []
    )

    # Extract @name
    if content =~ /@name\s*=\s*['"]([^'"]+)['"]/
      structure.name = $1
    end

    # Extract @analysis_category
    if content =~ /@analysis_category\s*=\s*['"]([^'"]+)['"]/
      structure.analysis_category = $1
    end

    # Extract @description
    if content =~ /@description\s*=\s*<<-?(\w+)(.+?)^\s*\1/m
      structure.description = $2.strip
    elsif content =~ /@description\s*=\s*['"]([^'"]+)['"]/
      structure.description = $1
    end

    # Extract @params['process_mode']
    if content =~ /@params\s*\[\s*['"]process_mode['"]\s*\]\s*=\s*['"]([^'"]+)['"]/
      structure.process_mode = $1
    end

    # Extract @required_columns
    if content =~ /@required_columns\s*=\s*\[([^\]]+)\]/
      structure.required_columns = $1.scan(/['"]([^'"]+)['"']/).flatten
    end

    # Extract @required_params
    if content =~ /@required_params\s*=\s*\[([^\]]+)\]/
      structure.required_params = $1.scan(/['"]([^'"]+)['"']/).flatten
    end

    # Extract @modules
    if content =~ /@modules\s*=\s*\[([^\]]+)\]/
      structure.modules = $1.scan(/['"]([^'"]+)['"']/).flatten
    end

    # Extract @inherit_columns
    if content =~ /@inherit_columns\s*=\s*\[([^\]]+)\]/
      structure.inherit_columns = $1.scan(/['"]([^'"]+)['"']/).flatten
    end

    # Extract @inherit_tags
    if content =~ /@inherit_tags\s*=\s*\[([^\]]+)\]/
      structure.inherit_tags = $1.scan(/['"]([^'"]+)['"']/).flatten
    end

    # Extract params (basic key-value pairs)
    content.scan(/@params\s*\[\s*['"'](\w+)['"']\s*\]\s*=\s*(.+)$/) do |key, value|
      # Skip context/description metadata
      next if key.include?(',')
      structure.params[key] = value.strip
    end

    # Extract run_RApp call
    if content =~ /run_RApp\s*\(\s*['"]([^'"]+)['"]/
      structure.ezrun_app = $1
    end

    # Extract defined methods
    content.scan(/^\s*def\s+(\w+)/) do |method_name|
      structure.methods << method_name[0]
    end

    structure
  end

  def list_apps
    Dir.glob(File.join(@lib_path, '*App.rb')).map do |file|
      File.basename(file, '.rb')
    end.sort
  end

  def compare_apps(app1_name, app2_name)
    app1 = parse_app(app1_name)
    app2 = parse_app(app2_name)

    return nil if app1.nil? || app2.nil?

    {
      app1: app1_name,
      app2: app2_name,
      differences: {
        analysis_category: [app1.analysis_category, app2.analysis_category],
        process_mode: [app1.process_mode, app2.process_mode],
        required_columns: {
          only_in_app1: app1.required_columns - app2.required_columns,
          only_in_app2: app2.required_columns - app1.required_columns,
          common: app1.required_columns & app2.required_columns
        },
        modules: {
          only_in_app1: app1.modules - app2.modules,
          only_in_app2: app2.modules - app1.modules,
          common: app1.modules & app2.modules
        },
        params: {
          only_in_app1: app1.params.keys - app2.params.keys,
          only_in_app2: app2.params.keys - app1.params.keys,
          common: app1.params.keys & app2.params.keys
        },
        methods: {
          only_in_app1: app1.methods - app2.methods,
          only_in_app2: app2.methods - app1.methods,
          common: app1.methods & app2.methods
        }
      }
    }
  end
end

# CLI interface
if __FILE__ == $0
  require 'json'
  
  lib_path = ARGV[0] || SushiAppParser::DEFAULT_LIB_PATH
  app_name = ARGV[1]
  
  parser = SushiAppParser.new(lib_path)
  
  if app_name
    structure = parser.parse_app(app_name)
    if structure
      puts JSON.pretty_generate(structure.to_h)
    else
      puts "App '#{app_name}' not found"
      exit 1
    end
  else
    puts "Available apps:"
    parser.list_apps.each { |app| puts "  - #{app}" }
  end
end
