# SUSHI Self-Maintenance MCP Server

A Model Context Protocol (MCP) server for SUSHI framework self-maintenance and development support.

## Overview

This MCP server provides AI-assisted development support for the SUSHI bioinformatics framework. It enables AI coding assistants (Cursor, Claude Code, etc.) to interact with the SUSHI codebase through a standardized protocol.

### Current Status: Phase 0 (Proof of Concept)

Phase 0 establishes basic connectivity between MCP clients and this server via STDIO transport.

### Goals

- **Phase 0**: Verify MCP client connection via STDIO (current)
- **Phase 1**: Add `search_repo`, `read_file` tools with safety limits
- **Phase 2**: Add `list_tree`, `find_files` for structure analysis
- **Phase 3**: Skills Retrieval using `skills/sushi.md`
- **Phase 4+**: Architecture support, patch proposals, limited execution

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
│  │  STDIO Loop  │ │  JSON-RPC    │ │  hello_world (Phase 0)   │ │
│  │              │ │  Handling    │ │  search_repo (Phase 1)   │ │
│  └──────────────┘ └──────────────┘ │  read_file   (Phase 1)   │ │
│                                    └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Features (Phase 0)

| Feature | Description |
|---------|-------------|
| **Protocol** | MCP JSON-RPC 2.0 via STDIO |
| **Transport** | Standard Input/Output |
| **Tools** | `hello_world` (connectivity test) |
| **Environment** | Ruby 3.3.7 (Standard Library only) |

## Directory Structure

```
SUSHI_self_maintenance_mcp_server/
├── bin/
│   └── sushi_mcp_server           # Executable entry point
├── lib/
│   └── sushi_mcp/
│       ├── version.rb             # Version constant
│       ├── server.rb              # Main STDIO loop
│       ├── protocol.rb            # JSON-RPC message handling
│       ├── tool_registry.rb       # Tool registration/dispatch
│       └── tools/
│           ├── base_tool.rb       # Tool base class
│           └── hello_world.rb     # Test tool (Phase 0)
├── log/
│   ├── sushi_mcp_server_phase0_20260106.md   # Phase 0 implementation plan
│   └── sushi_self_maintenance_plan_20260106.md # Overall design document
├── skills/
│   └── sushi.md                   # Comprehensive SUSHI Skills Document
├── test_requests.jsonl            # Test input for manual verification
├── LICENSE
└── README.md
```

## Installation

### Prerequisites

- Ruby 3.3.7 (uses standard library only, no gem installation required)

### Setup

```bash
# Clone or navigate to the repository
cd /srv/sushi/masa_test_sushi_20260106/SUSHI_self_maintenance_mcp_server

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
      "args": ["/srv/sushi/masa_test_sushi_20260106/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server"],
      "env": {}
    }
  }
}
```

After saving, restart Cursor. The server should appear in the MCP server list.

### Claude Code (CLI)

Add the following to your Claude Code MCP configuration:

**Location**: `~/.claude/mcp.json` (or equivalent)

```json
{
  "mcpServers": {
    "sushi-mcp-server": {
      "command": "ruby",
      "args": ["/srv/sushi/masa_test_sushi_20260106/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server"],
      "env": {}
    }
  }
}
```

### VS Code with MCP Extension

If using VS Code with an MCP extension, add to your workspace or user settings:

```json
{
  "mcp.servers": {
    "sushi-mcp-server": {
      "command": "ruby",
      "args": ["/srv/sushi/masa_test_sushi_20260106/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server"]
    }
  }
}
```

## Manual Testing

### Method 1: Pipe from File (Recommended)

Use the provided test file to send multiple requests:

```bash
cd /srv/sushi/masa_test_sushi_20260106/SUSHI_self_maintenance_mcp_server
cat test_requests.jsonl | bin/sushi_mcp_server
```

Expected output:
```json
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{}},"serverInfo":{"name":"sushi-mcp-server","version":"0.1.0"}}}
{"jsonrpc":"2.0","id":2,"result":{"tools":[{"name":"hello_world","description":"Returns a hello message from SUSHI MCP Server","inputSchema":{"type":"object","properties":{"name":{"type":"string","description":"Name to greet (optional)"}}}}]}}
{"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"Hello, Cursor User! This is SUSHI MCP Server (Phase 0)."}]}}
```

### Method 2: Interactive Mode

Start the server and type JSON requests manually:

```bash
cd /srv/sushi/masa_test_sushi_20260106/SUSHI_self_maintenance_mcp_server
bin/sushi_mcp_server
```

Then paste each JSON request (one per line):

**1. Initialize (required first):**
```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
```

**2. List available tools:**
```json
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
```

**3. Call hello_world tool:**
```json
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"hello_world","arguments":{"name":"Developer"}}}
```

Press `Ctrl+D` (EOF) to exit.

### Method 3: Single Request with Echo

Test individual requests quickly:

```bash
# Initialize
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | bin/sushi_mcp_server

# List tools
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | bin/sushi_mcp_server

# Call hello_world
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"hello_world","arguments":{}}}' | bin/sushi_mcp_server
```

## MCP Protocol Reference

### Supported Methods (Phase 0)

| Method | Description |
|--------|-------------|
| `initialize` | Exchange protocol version and capabilities |
| `initialized` | Notification that initialization is complete (no response) |
| `tools/list` | List available tools with their schemas |
| `tools/call` | Execute a tool with given arguments |

### Available Tools (Phase 0)

| Tool | Description | Arguments |
|------|-------------|-----------|
| `hello_world` | Returns a greeting message | `name` (optional): Name to greet |

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
2. Check stderr for error messages
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
        # Implementation
        text_content("Result: #{arguments['param1']}")
      end
    end
  end
end
```

2. Register in `lib/sushi_mcp/tool_registry.rb`:

```ruby
require_relative 'tools/my_tool'

def register_tools
  register(Tools::HelloWorld.new)
  register(Tools::MyTool.new)  # Add this line
end
```

## Related Documents

- [Phase 0 Implementation Plan](log/sushi_mcp_server_phase0_20260106.md)
- [Overall Design Document](log/sushi_self_maintenance_plan_20260106.md)
- [SUSHI Skills Document](skills/sushi.md)

## License

See [LICENSE](LICENSE) file.

---

**Version**: 0.1.0 (Phase 0)  
**Last Updated**: 2026-01-06
