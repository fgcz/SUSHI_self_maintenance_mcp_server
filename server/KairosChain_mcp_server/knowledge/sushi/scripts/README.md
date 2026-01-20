# SUSHI Scripts

This directory contains standalone Ruby scripts for SUSHI application development and analysis.

## Available Scripts

| Script | Description |
|--------|-------------|
| `app_parser.rb` | Core library for parsing SUSHI App files |
| `list_sushi_apps.rb` | List all available SUSHI Apps with categorization |
| `get_app_structure.rb` | Analyze and display the structure of a SUSHI App |
| `compare_apps.rb` | Compare two SUSHI Apps to see their differences |
| `get_app_template.rb` | Generate a template for creating a new SUSHI App |

## Usage

All scripts can be run directly from the command line. Default SUSHI lib path is `/srv/sushi/production/master/lib`.

### List SUSHI Apps

```bash
# List all apps
ruby list_sushi_apps.rb

# List apps with filter
ruby list_sushi_apps.rb /srv/sushi/production/master/lib "single"
```

### Get App Structure

```bash
# Analyze an app
ruby get_app_structure.rb FastqcApp

# With custom lib path
ruby get_app_structure.rb FastqcApp /srv/sushi/test_sushi/master/lib
```

### Compare Apps

```bash
# Compare two apps
ruby compare_apps.rb FastqcApp Fastqc2App
```

### Generate App Template

```bash
# Generate generic template
ruby get_app_template.rb MyNewApp

# Generate based on existing app
ruby get_app_template.rb MyNewApp FastqcApp

# With category
ruby get_app_template.rb MyNewApp FastqcApp "QC"
```

## Using as MCP Resource

These scripts can be accessed via MCP Resource mechanism. LLMs can:

1. Read script contents to understand the logic
2. Execute scripts with appropriate parameters
3. Use the output for SUSHI development tasks

Example MCP interaction:
```
knowledge_scripts name:sushi
→ Returns list of available scripts

# Then execute via shell
ruby /path/to/knowledge/sushi/scripts/list_sushi_apps.rb
```
