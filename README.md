# SUSHI Self-Maintenance MCP Server

A Model Context Protocol (MCP) server for SUSHI framework self-maintenance and development support.

## Overview

This MCP server provides AI-assisted development support for the SUSHI bioinformatics framework. It enables AI coding assistants (Cursor, Claude Code, etc.) to interact with the SUSHI codebase through a standardized protocol.

### Current Status: Phase 4 Complete

All core phases are implemented:
- **Phase 0**: Basic MCP connectivity via STDIO ✓
- **Phase 1**: `search_repo`, `read_file` with safety limits ✓
- **Phase 2**: `list_tree`, `find_files`, `list_sushi_apps` for structure analysis ✓
- **Phase 3**: Skills Retrieval using `skills/sushi.md` ✓
- **Phase 4**: SUSHI App development support tools ✓

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    MCP Client (Cursor / Claude Code)            │
└───────────────────────────────┬─────────────────────────────────┘
                                │ STDIO (stdin/stdout JSON-RPC)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SUSHI MCP Server                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │    Server    │ │   Protocol   │ │     Tool Registry        │ │
│  │  STDIO Loop  │ │  JSON-RPC    │ │  12 Tools Available      │ │
│  │              │ │  Handling    │ │  (see table below)       │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
│                                                                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │    Safety    │ │ Skills Parser│ │      App Parser          │ │
│  │   Module     │ │  (sushi.md)  │ │  (Ruby App Analysis)     │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Available Tools

| Tool | Category | Description |
|------|----------|-------------|
| `hello_world` | Test | Returns a greeting message (connectivity test) |
| `search_repo` | Dev Support | Search for text patterns using grep/ripgrep |
| `read_file` | Dev Support | Read file contents with safety limits |
| `list_tree` | Structure | Display directory structure as tree |
| `find_files` | Structure | Find files matching glob patterns |
| `list_sushi_apps` | Structure | List all SUSHI Apps with categories |
| `skills_list` | Skills | List available documentation sections |
| `skills_get` | Skills | Get content of a specific section by ID |
| `skills_search` | Skills | Search documentation by keyword |
| `get_app_structure` | App Dev | Analyze SUSHI App structure (params, modules, etc.) |
| `get_app_template` | App Dev | Generate new App template from existing apps |
| `compare_apps` | App Dev | Compare two SUSHI Apps side by side |

## Directory Structure

```
SUSHI_self_maintenance_mcp_server/
├── bin/
│   └── sushi_mcp_server           # Executable entry point
├── config/
│   └── safety.yml                 # Safety configuration (blocklist, limits)
├── lib/
│   └── sushi_mcp/
│       ├── version.rb             # Version constant
│       ├── server.rb              # Main STDIO loop
│       ├── protocol.rb            # JSON-RPC message handling
│       ├── tool_registry.rb       # Tool registration/dispatch
│       ├── safety.rb              # Safety module (path validation)
│       ├── skills_parser.rb       # Markdown section parser
│       ├── app_parser.rb          # Ruby App structure analyzer
│       └── tools/
│           ├── base_tool.rb       # Tool base class
│           ├── hello_world.rb     # Test tool
│           ├── search_repo.rb     # Code search
│           ├── read_file.rb       # File reader
│           ├── list_tree.rb       # Directory tree
│           ├── find_files.rb      # Glob file finder
│           ├── list_sushi_apps.rb # App lister
│           ├── skills_list.rb     # Skills index
│           ├── skills_get.rb      # Skills section getter
│           ├── skills_search.rb   # Skills searcher
│           ├── get_app_structure.rb # App analyzer
│           ├── get_app_template.rb  # Template generator
│           └── compare_apps.rb    # App comparator
├── skills/
│   └── sushi.md                   # Comprehensive SUSHI Skills Document
├── sushi/
│   └── master/                    # SUSHI source code (read-only reference)
├── log/
│   ├── sushi_mcp_server_phase0_20260106.md
│   └── sushi_self_maintenance_plan_20260106.md
├── LICENSE
└── README.md
```

## Installation

### Prerequisites

- Ruby 3.3.7 (uses standard library only, no gem installation required)

### Setup

```bash
# Navigate to the repository
cd /srv/sushi/SUSHI_self_maintenance_mcp_server

# Verify the server is executable
chmod +x bin/sushi_mcp_server

# Test basic execution
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | bin/sushi_mcp_server
```

## Client Configuration

### Cursor IDE

Add the following to your Cursor MCP configuration file:

**Location**: `~/.cursor/mcp.json`

```json
{
  "mcpServers": {
    "sushi-mcp-server": {
      "command": "ruby",
      "args": ["/srv/sushi/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server"],
      "env": {}
    }
  }
}
```

After saving, restart Cursor. The server should appear in the MCP server list.

### Claude Code (CLI)

Add the following to your Claude Code MCP configuration:

**Location**: `~/.claude.json` (mcpServers section)

```json
{
  "mcpServers": {
    "sushi-mcp-server": {
      "command": "ruby",
      "args": ["/srv/sushi/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server"],
      "env": {}
    }
  }
}
```

## Workspace Configuration

The MCP server automatically detects and uses the workspace directory of the AI agent. This allows it to analyze SUSHI code in any SUSHI repository you're working in.

### Workspace Detection Priority

1. **MCP Client roots** - If the client (Cursor/Claude Code) provides workspace roots during initialization, those are used
2. **Environment variable** - `SUSHI_WORKSPACE` environment variable
3. **Default** - Falls back to the MCP server's own directory

### Using with Different SUSHI Repositories

When you open a SUSHI repository in Cursor or Claude Code, the MCP server will automatically search for the lib directory in these locations (in order):

- `master/lib/` - Standard SUSHI repository structure
- `sushi/master/lib/` - MCP server's bundled copy
- `lib/` - Alternative structure

### Setting Workspace via Environment Variable

You can explicitly set the workspace in the Cursor MCP configuration:

```json
{
  "mcpServers": {
    "sushi-mcp-server": {
      "command": "ruby",
      "args": ["/srv/sushi/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server"],
      "env": {
        "SUSHI_WORKSPACE": "/path/to/your/sushi/repository"
      }
    }
  }
}
```

### Example: Working with Production SUSHI

```json
{
  "mcpServers": {
    "sushi-mcp-server": {
      "command": "ruby",
      "args": ["/srv/sushi/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server"],
      "env": {
        "SUSHI_WORKSPACE": "/srv/sushi/production"
      }
    }
  }
}
```

## Usage Examples

### List All Tools

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | ruby bin/sushi_mcp_server 2>/dev/null | jq '.result.tools[].name'
```

### Search for Code

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search_repo","arguments":{"query":"SushiFabric","path":"sushi/master/lib","max_results":10}}}' | ruby bin/sushi_mcp_server 2>/dev/null | jq -r '.result.content[0].text'
```

### List SUSHI Apps

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_sushi_apps","arguments":{}}}' | ruby bin/sushi_mcp_server 2>/dev/null | jq -r '.result.content[0].text'
```

### Get Skills Documentation

```bash
# List available sections
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"skills_list","arguments":{}}}' | ruby bin/sushi_mcp_server 2>/dev/null | jq -r '.result.content[0].text'

# Get specific section
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"skills_get","arguments":{"section_id":"DEV-010"}}}' | ruby bin/sushi_mcp_server 2>/dev/null | jq -r '.result.content[0].text'
```

### Analyze SUSHI App Structure

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_app_structure","arguments":{"app_name":"FastqcApp"}}}' | ruby bin/sushi_mcp_server 2>/dev/null | jq -r '.result.content[0].text'
```

### Generate New App Template

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_app_template","arguments":{"base_app":"FastqcApp","new_app_name":"MyQC"}}}' | ruby bin/sushi_mcp_server 2>/dev/null | jq -r '.result.content[0].text'
```

### Compare Two Apps

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"compare_apps","arguments":{"app1":"FastqcApp","app2":"STARApp"}}}' | ruby bin/sushi_mcp_server 2>/dev/null | jq -r '.result.content[0].text'
```

## Safety Features

The server includes safety measures to prevent unauthorized access:

- **SAFE_ROOT**: All file operations are restricted to the project directory
- **Blocklist**: Sensitive files (.env, *.key, credentials) are blocked
- **Output Limits**: Search results and file reads are truncated to prevent token overflow

Configuration in `config/safety.yml`:

```yaml
safe_root: "/srv/sushi/SUSHI_self_maintenance_mcp_server"
allowed_paths:
  - "sushi/master/lib"
  - "sushi/master/app"
  - "skills"
blocklist:
  - ".env*"
  - "*.key"
  - "*.pem"
  - "credentials*.yml.enc"
limits:
  max_read_bytes: 100000
  max_search_lines: 500
  max_tree_depth: 5
```

## Skills Document

The `skills/sushi.md` document contains comprehensive SUSHI documentation organized by section IDs:

| Section ID | Topic |
|------------|-------|
| ARCH-010, ARCH-020 | System Architecture, Data Flow |
| DEV-010 to DEV-060 | App Development (R, Ruby, Rmd, Parameters) |
| CLI-010 to CLI-030 | Command Line Usage |
| DEPLOY-010 to DEPLOY-030 | Deployment (Test, Production, Apache) |
| DB-010, DB-020 | Database Operations |
| JOBMGR-010, JOBMGR-020 | Job Manager |
| TROUBLE-010 to TROUBLE-030 | Troubleshooting |
| REF-010 | Quick Reference |

Use `skills_list` to see all sections and `skills_get` to retrieve specific content.

## Logging

- **Protocol messages**: Written to `stdout` (JSON only)
- **Log messages**: Written to `stderr` (prefixed with `[INFO]`, `[ERROR]`)

Log messages do not interfere with protocol communication.

## Troubleshooting

### Server doesn't start

1. Verify Ruby version: `ruby --version` (should be 3.3.7)
2. Check executable permission: `chmod +x bin/sushi_mcp_server`
3. Check for syntax errors: `ruby -c bin/sushi_mcp_server`

### No response from server

1. Ensure JSON is valid (single line, no trailing whitespace)
2. Check stderr for error messages: run without `2>/dev/null`
3. Verify the `method` field matches supported methods

### Cursor doesn't show the server

1. Verify the path in `~/.cursor/mcp.json` is absolute
2. Restart Cursor after configuration changes
3. Check Cursor's MCP logs for connection errors

## Development

### Adding a New Tool

1. Create a new file in `lib/sushi_mcp/tools/`:

```ruby
# lib/sushi_mcp/tools/my_tool.rb
require_relative 'base_tool'

module SushiMcp
  module Tools
    class MyTool < BaseTool
      def name
        'my_tool'
      end

      def description
        'Description of what this tool does'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            param1: { type: 'string', description: 'Parameter description' }
          },
          required: ['param1']
        }
      end

      def call(arguments)
        # Use @safety for path validation if needed
        # Implementation
        text_content("Result: #{arguments['param1']}")
      end
    end
  end
end
```

2. The tool will be auto-loaded. Add registration in `lib/sushi_mcp/tool_registry.rb` if using a non-standard class name:

```ruby
register_if_defined('SushiMcp::Tools::MyTool')
```

## Related Documents

- [Phase 0 Implementation Plan](log/sushi_mcp_server_phase0_20260106.md)
- [Overall Design Document](log/sushi_self_maintenance_plan_20260106.md)
- [SUSHI Skills Document](skills/sushi.md)

## License

See [LICENSE](LICENSE) file.

---

**Version**: 0.2.0 (Phase 1-4 Complete)  
**Last Updated**: 2026-01-15
