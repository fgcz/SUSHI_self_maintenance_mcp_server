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

Add the MCP server to your Claude Code configuration:

**Method 1: Using `claude mcp add` command (Recommended)**

```bash
claude mcp add sushi-mcp-server ruby /srv/sushi/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server
```

**Method 2: Manual configuration**

Edit `~/.claude.json`:

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

**Verify installation:**

```bash
claude mcp list
```

You should see `sushi-mcp-server` in the list.

## Workspace Configuration

The MCP server automatically detects and uses the **current working directory** of the AI agent (Cursor, Claude Code, etc.) as the SUSHI workspace. This allows it to analyze SUSHI code in any SUSHI repository you're working in.

### Default Behavior (Recommended)

By default, the MCP server uses the directory where the AI agent is currently working.

**Cursor configuration** (`~/.cursor/mcp.json`):
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

**Claude Code**: Use the default installation (no env needed):
```bash
claude mcp add sushi-mcp-server ruby /srv/sushi/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server
```

**How it works:**
- When you open `/srv/sushi/production` in Cursor/Claude Code → MCP server analyzes code in `/srv/sushi/production/master/lib/`
- When you `cd /home/user/my_sushi_dev` and run Claude Code → MCP server analyzes code in that directory
- SUSHI code in the current workspace **can be edited** by the AI agent (this is intended behavior for development)

### Workspace Detection Priority

1. **MCP Client roots** - Workspace information provided by the client during initialization (Cursor/Claude Code automatically sends this)
2. **Environment variable `SUSHI_WORKSPACE`** - Explicit override if needed
3. **Default** - Falls back to the MCP server's own directory

### SUSHI lib Path Auto-Detection

The MCP server searches for the lib directory in these locations (in order):

- `master/lib/` - Standard SUSHI repository structure
- `sushi/master/lib/` - MCP server's bundled reference copy
- `lib/` - Alternative structure

### Important: Read-Only Reference Copy

The SUSHI code bundled within this MCP server (`sushi/master/lib/`) is a **read-only reference copy**:

- Protected by `.cursorignore` (Cursor) and `.claudeignore` (Claude Code) to prevent accidental edits
- MCP server provides **read-only tools only** (no write operations)
- For actual SUSHI development, work in a separate SUSHI repository

### Setting Workspace via Environment Variable (Optional)

If you want to always use a specific SUSHI repository regardless of the current directory:

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

### Example Configurations

**Example 1: Default (use AI agent's current directory)**

Cursor (`~/.cursor/mcp.json`):
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

Claude Code:
```bash
claude mcp add sushi-mcp-server ruby /srv/sushi/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server
```

- Open any SUSHI repository in Cursor / `cd` to it in Claude Code
- MCP server automatically uses that repository

**Example 2: Always use production SUSHI**

Cursor (`~/.cursor/mcp.json`):
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

Claude Code:
```bash
claude mcp add sushi-mcp-server -e SUSHI_WORKSPACE=/srv/sushi/production ruby /srv/sushi/SUSHI_self_maintenance_mcp_server/bin/sushi_mcp_server
```

- Always analyzes production SUSHI code
- Regardless of which directory is open

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

---

## Pure Skills Design: skills.rb vs skills.md

### Philosophy

The SUSHI MCP Server implements a **Pure Skills Design** that goes beyond traditional documentation-based skill definitions.

#### The Fundamental Question

> **Where should AI capabilities be defined: in prompts, tools, or structure?**

| Approach | Characteristics |
|----------|-----------------|
| **skills.md (Markdown)** | Declarative text; human-readable but not executable |
| **skills.rb (Ruby DSL)** | Executable structure; self-referential and evolvable |

### Key Differences

| Aspect | skills.md | skills.rb |
|--------|-----------|-----------|
| **Nature** | Description (説明) | Definition (定義) |
| **Executability** | ❌ Cannot be evaluated | ✅ Parseable, validatable |
| **Side Effects** | Implicit in operator logic | Named & scoped contexts |
| **Evolution** | External manual updates | Built-in evolution rules |
| **Self-Reference** | None | Structural via `Kairos` module |
| **Auditability** | Fragmented | Native (AST-based diff) |
| **History** | Git commits only | Append-only snapshots |
| **AI Role** | Reader of documentation | Part of the structure |

### Design Principles (Pure Skills)

1. **P1: Skills Are Pure by Default**
   - No implicit global state mutation
   - Only explicitly declared inputs may be read
   - Only explicitly declared state may be modified

2. **P2: Side Effects Are Named and Scoped**
   - Any mutation or execution must occur inside a *named context*
   - Unnamed or implicit side effects are forbidden

3. **P3: Self-Reference Is Structural, Not Magical**
   - Skills may reference their own definition and history
   - Skills may NOT arbitrarily rewrite themselves
   - All self-modification must follow pre-declared evolution rules

4. **P4: Evolution Is Constrained (Minimum-Nomic)**
   - Rules can evolve
   - The *rules governing evolution* are strictly limited
   - Core invariants (e.g., `core_safety`) are immutable

### Example: Pure Skill Definition

```ruby
skill :pipeline_generation do
  version "1.0"
  
  inputs :genomic_context, :parameters
  
  guarantees do
    reproducible
    explainable
  end
  
  # Pure behavior: no side effects allowed here
  behavior do |input|
    Pipeline.plan(input)
  end
  
  # Named side-effect context
  effect :execution do
    requires :human_approval
    records :audit_trail
    
    run do |plan|
      Executor.run(plan)
    end
  end
  
  # Evolution rules
  evolve do
    allow :parameter_defaults
    deny :guarantees
  end
end
```

### Self-Referential Introspection

```ruby
skill :self_inspection do
  behavior do
    Kairos.skills.map do |skill|
      {
        id: skill.id,
        version: skill.version,
        guarantees: skill.guarantees,
        can_evolve: skill.evolution_rules
      }
    end
  end
end
```

### When to Enable Evolution

| Setting | Usage |
|---------|-------|
| `evolution_enabled: false` | **Default**: Stable operation, skills are read-only |
| `evolution_enabled: true` | **Explicit sessions**: Human-supervised improvement cycles |

**Safe evolution workflow**:

```
1. Set evolution_enabled: true
2. LLM proposes skill changes (skills_evolve propose)
3. Human reviews and approves
4. Apply changes (skills_evolve apply approved:true)
5. Verify behavior
6. Set evolution_enabled: false
```

### Position in Architecture

```
skills.md ─────────────────────────────────────┐
  │                                            │
  │ (Human-readable reference, backward compat) │
  │                                            │
  ▼                                            │
skills.rb (Ruby DSL) ◀────────────────────────┘
  │
  ▼
Ruby AST (parse/validate/diff)
  │
  ▼
MCP Server (context-specific projection)
  │
  ▼
AI Coding Agent (Claude / Cursor / Antigravity)
```

This design treats skills as:

- **Typed rule contexts** (not free-form text)
- **Pure-by-default transformations** (functional programming)
- **Auditable, evolvable subjects** (constitutional systems)

### Pure Skills Documentation

- [Pure Skill Design Concept](log/kairos_pure_skill_design_self_referential_skills_idea_20260115.md)
- [DSL/AST Design Proposal](log/kairos_skills_dsl_ast_design_proposal_20260115.md)
- [Self-Evolution Implementation](log/kairos_self_evolution_implementation_plan_20260115.md)
- [Implementation Log](log/kairos_pure_skill_design_self_referential_skills_implementation_log_20260115.md)

---

## License

See [LICENSE](LICENSE) file.

---

**Version**: 0.3.0 (Pure Skills DSL Complete)  
**Last Updated**: 2026-01-15
