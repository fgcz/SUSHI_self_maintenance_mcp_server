#!/usr/bin/env ruby
# encoding: utf-8
# List SUSHI Apps - List all available SUSHI applications with categorization
#
# Usage:
#   ruby list_sushi_apps.rb [lib_path] [filter]
#
# Examples:
#   ruby list_sushi_apps.rb                                    # List all apps
#   ruby list_sushi_apps.rb /srv/sushi/production/master/lib   # Custom path
#   ruby list_sushi_apps.rb /srv/sushi/production/master/lib "single"  # Filter

DEFAULT_LIB_PATH = '/srv/sushi/production/master/lib'

def categorize_apps(apps)
  categories = {
    'Single Cell' => [],
    'QC' => [],
    'Alignment' => [],
    'Variant Calling' => [],
    'Differential Expression' => [],
    'Assembly' => [],
    'Other' => []
  }

  apps.each do |app|
    case app
    when /^(Sc|SingleCell|CellRanger|Seurat|Velocyto|Space|Xenium|Visium)/i
      categories['Single Cell'] << app
    when /(Qc|Fastqc|Stats|Bias)App$/i
      categories['QC'] << app
    when /^(STAR|BWA|Bowtie|Minimap|Pbmm)/i
      categories['Alignment'] << app
    when /(Gatk|Mutect|Delly|Haplotype|Vcf)/i
      categories['Variant Calling'] << app
    when /^(DESeq|EdgeR|Limma|Diff)/i
      categories['Differential Expression'] << app
    when /^(Canu|Spades|Hifiasm|Quast|Prokka)/i
      categories['Assembly'] << app
    else
      categories['Other'] << app
    end
  end

  # Remove empty categories
  categories.reject { |_, v| v.empty? }
end

def list_apps(lib_path, filter = nil)
  unless File.directory?(lib_path)
    puts "Error: SUSHI lib directory not found at #{lib_path}"
    exit 1
  end

  # Find all *App.rb files
  app_files = Dir.glob(File.join(lib_path, '*App.rb')).sort
  apps = app_files.map { |file| File.basename(file, '.rb') }

  # Apply filter if provided
  if filter && !filter.empty?
    pattern = Regexp.new(filter, Regexp::IGNORECASE)
    apps = apps.select { |app| app.match?(pattern) }
  end

  if apps.empty?
    if filter
      puts "No SUSHI Apps found matching '#{filter}'"
    else
      puts "No SUSHI Apps found in #{lib_path}"
    end
    return
  end

  # Group apps by category
  puts "Found #{apps.size} SUSHI Apps:\n\n"
  
  categories = categorize_apps(apps)
  categories.each do |category, category_apps|
    puts "## #{category} (#{category_apps.size})"
    category_apps.each { |app| puts "  - #{app}" }
    puts
  end
end

# CLI interface
if __FILE__ == $0
  lib_path = ARGV[0] || DEFAULT_LIB_PATH
  filter = ARGV[1]
  
  list_apps(lib_path, filter)
end
