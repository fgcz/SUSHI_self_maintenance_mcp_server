require_relative 'base_tool'

module SushiMcp
  module Tools
    class ListSushiApps < BaseTool
      def name
        'list_sushi_apps'
      end

      def description
        'List all available SUSHI Apps. Returns the app class names found in sushi/master/lib/'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            filter: {
              type: 'string',
              description: 'Optional filter pattern to match app names (case-insensitive)'
            }
          }
        }
      end

      def call(arguments)
        filter = arguments['filter']

        begin
          lib_path = @safety&.sushi_lib_path || File.join(File.expand_path('../../..', __dir__), 'sushi/master/lib')

          unless File.directory?(lib_path)
            return text_content("Error: SUSHI lib directory not found. Searched paths include: master/lib, sushi/master/lib")
          end

          # Find all *App.rb files
          app_files = Dir.glob(File.join(lib_path, '*App.rb')).sort
          
          apps = app_files.map do |file|
            File.basename(file, '.rb')
          end

          # Apply filter if provided
          if filter && !filter.empty?
            pattern = Regexp.new(filter, Regexp::IGNORECASE)
            apps = apps.select { |app| app.match?(pattern) }
          end

          if apps.empty?
            if filter
              return text_content("No SUSHI Apps found matching '#{filter}'")
            else
              return text_content("No SUSHI Apps found in #{SUSHI_LIB_PATH}")
            end
          end

          # Group apps by category (based on common prefixes/patterns)
          output = "Found #{apps.size} SUSHI Apps:\n\n"
          
          categories = categorize_apps(apps)
          categories.each do |category, category_apps|
            output += "## #{category} (#{category_apps.size})\n"
            category_apps.each { |app| output += "  - #{app}\n" }
            output += "\n"
          end

          text_content(output)
        rescue StandardError => e
          text_content("Error: #{e.message}")
        end
      end

      private

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
    end
  end
end
