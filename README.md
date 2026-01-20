# SUSHI Self-Maintenance MCP Server

A Model Context Protocol (MCP) server for SUSHI framework self-maintenance and development support.

## Overview

This project provides an AI-assisted development environment for the SUSHI bioinformatics framework. It integrates the [KairosChain](https://github.com/masaomi/KairosChain_2026) MCP server framework to deliver intelligent code analysis, navigation, and documentation retrieval capabilities.

### Key Integration: KairosChain 
The core MCP server logic is derived from **KairosChain** and resides in the `server/` directory as a mapped **Git Subtree**. This allows SUSHI to benefit from the latest KairosChain advancements while maintaining its own specific knowledge base.

## Architecture & Directory Structure

```
SUSHI_self_maintenance_mcp_server/
├── server/
│   └── KairosChain_mcp_server/   <-- Core Server (Git Subtree)
│       ├── bin/                  # Executable entry point
│       ├── config/               # Safety & Server config
│       ├── knowledge/
│       │   └── sushi/            # SUSHI-Specific Knowledge Base
│       ├── lib/                  # Application logic
│       ├── skills/               # Skills & Capabilities
│       └── ...
├── LICENSE
└── README.md
```

## Installation

### Prerequisites
- **Ruby 3.3.7** (standard library only)
- **Git** (for subtree management)

### Setup

1. **Navigate to the repository**
   ```bash
   cd /srv/sushi/SUSHI_self_maintenance_mcp_server
   ```

2. **Install dependencies**
   The server logic is inside the subtree. You need to run bundle install there.
   ```bash
   cd server/KairosChain_mcp_server
   bundle install
   ```

3. **Make executable**
   ```bash
   chmod +x bin/sushi_mcp_server
   ```

4. **Test connectivity**
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | bin/sushi_mcp_server
   ```

## Client Configuration

### Cursor IDE

Add the following to your Cursor MCP configuration file (`~/.cursor/mcp.json`). Note the path to the executable inside `server/KairosChain_mcp_server`.

```json
{
  "mcpServers": {
    "sushi-mcp-server": {
      "command": "ruby",
      "args": ["/srv/sushi/SUSHI_self_maintenance_mcp_server/server/KairosChain_mcp_server/bin/sushi_mcp_server"],
      "env": {}
    }
  }
}
```

### Claude Code

**Command Line:**
```bash
claude mcp add sushi-mcp-server ruby /srv/sushi/SUSHI_self_maintenance_mcp_server/server/KairosChain_mcp_server/bin/sushi_mcp_server
```

**Configuration File (`~/.claude.json`):**
```json
{
  "mcpServers": {
    "sushi-mcp-server": {
      "command": "ruby",
      "args": ["/srv/sushi/SUSHI_self_maintenance_mcp_server/server/KairosChain_mcp_server/bin/sushi_mcp_server"],
      "env": {}
    }
  }
}
```

## Maintenance & Synchronization

This repository uses **Git Subtree** to manage the core server code from `KairosChain_2026`.

### Updating the Server (Pull from Upstream)

To fetch the latest changes from the KairosChain repository (Main Branch) into your local `server/` directory:

```bash
# Register remote (one-time setup)
git remote add kairos_upstream https://github.com/masaomi/KairosChain_2026

# Pull updates into server/ directory
git subtree pull --prefix=server kairos_upstream main --squash
```

### Pushing Changes Upstream

If you make improvements to the core server code inside `server/` that should be shared back to KairosChain:

```bash
git subtree push --prefix=server kairos_upstream main
```

### SUSHI-Specific Knowledge & Skills

- **Knowledge**: SUSHI-specific documentation is located in `server/KairosChain_mcp_server/knowledge/sushi/`.
- **Skills**: SUSHI-specific skills (if any) are located in `server/KairosChain_mcp_server/skills/`.

#### Legacy Tools (Scripts)
The original SUSHI tools (`list_sushi_apps`, `get_app_structure`, etc.) are preserved as executable scripts in:
`server/KairosChain_mcp_server/knowledge/sushi/scripts/`

These can be used by the AI agent via command execution or analyzed as resources.

**Caution**: When running `git subtree pull`, git will usually auto-merge safely, but be aware that files inside `server/` are tracked by both the external repository and this repository.

## Usage

The server automatically detects the SUSHI workspace from your current working directory.

### Available Tools

(This list depends on the version of KairosChain installed)

- **search_repo**: Semantic/grep search through codebase
- **read_file**: Read file contents with safety limits
- **skills_get**: Retrieve SUSHI documentation (e.g., `skills_get(section_id: "DEV-010")`)
- **get_app_structure**: Analyze SUSHI App ruby files

For a full list of tools and capabilities, refer to the [KairosChain Documentation](https://github.com/masaomi/KairosChain_2026).

## License

See [LICENSE](LICENSE) file.
