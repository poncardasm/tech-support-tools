# IT Knowledge CLI (macOS)

An offline-capable Q&A CLI for L1 support that answers common IT questions instantly without leaving the terminal or making a Google search. Uses a local embeddings database so ticket data never leaves the network.

**Target feel:** having a senior IT engineer on the team who responds in 200ms.

## Features

- **Offline-first**: Works without internet after initial setup
- **Vector search**: Uses embeddings for semantic similarity matching
- **Local LLM**: Integrates with Ollama for local embedding generation
- **Fast**: Returns results in under 500ms
- **Markdown support**: Index KB articles with YAML frontmatter
- **macOS native**: Stores data in `~/.config/it-kb/`
- **Homebrew ready**: Installable via Homebrew formula

## Prerequisites

1. **Python 3.10+** - macOS typically has Python 3 pre-installed. Check with:
   ```bash
   python3 --version
   ```

2. **Ollama** - Local LLM runner for embeddings

### Installing Ollama on macOS

```bash
# Install via Homebrew
brew install ollama

# Or download from https://ollama.com

# Pull the embedding model
ollama pull nomic-embed-text

# Start Ollama service
brew services start ollama

# Or run manually
ollama serve
```

Verify Ollama is working:
```bash
ollama list
# Should show: nomic-embed-text
```

## Installation

### Option 1: From Source (Development)

```bash
# Navigate to the project
cd 05-it-knowledge-cli/macos

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install in development mode
pip install -e .

# Verify installation
it-kb --help
```

### Option 2: Homebrew (Recommended for End Users)

```bash
# Tap the repository (when published)
brew tap your-org/l1-support-tools

# Install
brew install it-kb

# Or install directly from this directory
brew install --build-from-source ./Formula/it-kb.rb
```

## Quick Start

### 1. Index Sample Articles

```bash
# Index the included sample KB articles
it-kb --index ./kb/sample-articles/

# You should see:
# Indexed: KB-1001 — Set Up 2FA for Microsoft Entra ID
# Indexed: KB-2041 — Reset Outlook Profile (macOS)
# Indexed: KB-3001 — VPN DNS Override Configuration (macOS)
# Indexed: KB-5001 — macOS Keychain Certificate Issues
```

### 2. Search the Knowledge Base

```bash
# Search for Outlook issues
it-kb "reset outlook profile"

# Search with more results
it-kb "vpn dns" --top 5

# Search for 2FA setup
it-kb "how do I set up 2FA"

# Search for macOS-specific issues
it-kb "keychain certificate problems"
```

### 3. List All Articles

```bash
it-kb --list
```

## Usage

### Search Commands

```bash
# Basic search
it-kb "your search query"

# Get top 5 results instead of default 3
it-kb "password reset" --top 5

# Show specific article by ID
it-kb --id KB-2041
```

### Indexing Commands

```bash
# Index a directory of markdown files
it-kb --index /path/to/kb-articles/

# Index with a specific category
it-kb --index ./kb/ --category "networking"

# List all indexed articles
it-kb --list

# List articles in a specific category
it-kb --list --category "email"
```

### Adding New Articles

```bash
# Add a new article interactively
it-kb --add "Article Title" --category "category"

# Then type your content and press Ctrl+D when done
```

## Article Format

KB articles are Markdown files with YAML frontmatter:

```markdown
---
id: KB-2041
title: Reset Outlook Profile (macOS)
category: email
products: [outlook, microsoft-365]
last_updated: 2024-02-01
---

# Reset Outlook Profile (macOS)

Steps to reset an Outlook profile on macOS:

1. Quit Outlook completely (Cmd+Q)
2. Open Finder → Go → Go to Folder
3. Enter: `~/Library/Group Containers/UBF8T346G9.Office/Outlook/`
4. Rename `Outlook 15 Profiles` folder to `Outlook 15 Profiles Backup`
5. Restart Outlook
6. Reconfigure your account
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | No | Unique identifier (auto-generated from filename if missing) |
| `title` | No | Article title (auto-generated from filename if missing) |
| `category` | No | Article category for filtering |
| `products` | No | List of related products |
| `last_updated` | No | Date in YYYY-MM-DD format |

## Configuration

The CLI stores its data in:

```
~/.config/it-kb/
├── index.db          # Vector database with articles and embeddings
└── config.yaml       # Future: configuration file (not yet implemented)
```

To reset the knowledge base:

```bash
# Delete the database
rm ~/.config/it-kb/index.db

# Or remove the entire config directory
rm -rf ~/.config/it-kb/
```

## Sample Output

```
$ it-kb "reset outlook profile"

Top 1 (similarity: 0.94):
KB-2041 — Reset Outlook Profile (macOS)
Category: email
============================================================
# Reset Outlook Profile (macOS)

Steps to reset an Outlook profile on macOS:

1. Quit Outlook completely (Cmd+Q)
2. Open Finder → Go → Go to Folder
3. Enter: `~/Library/Group Containers/UBF8T346G9.Office/Outlook/`
...
```

## Architecture

```
it-knowledge-cli/
├── it_kb/                 # Main package
│   ├── __init__.py        # Package metadata
│   ├── __main__.py        # CLI entry point (Click)
│   ├── config.py          # macOS path configuration (~/.config/)
│   ├── embeddings.py      # Ollama embedding integration
│   ├── indexer.py         # Database and indexing logic
│   └── search.py          # Vector similarity search
├── kb/
│   └── sample-articles/   # Sample KB articles
├── tests/
│   └── test_search.py     # pytest test suite
├── Formula/
│   └── it-kb.rb           # Homebrew formula
├── pyproject.toml         # Package configuration
└── README.md              # This file
```

### Technology Stack

- **CLI Framework**: Click
- **Vector Database**: SQLite with sqlite-vec extension
- **Embeddings**: Ollama (nomic-embed-text model, 768-dim)
- **Frontmatter Parsing**: python-frontmatter
- **Testing**: pytest
- **Packaging**: Homebrew

## How It Works

1. **Indexing**: Markdown files are parsed, embeddings are generated via Ollama at `localhost:11434`, and both content and vectors are stored in SQLite
2. **Search**: Query is converted to embedding using Ollama, vector similarity search finds closest matches in sqlite-vec
3. **Results**: Top-N articles returned with similarity scores (0-1 range)

## Testing

Run the test suite:

```bash
# Install dev dependencies
pip install -e ".[dev]"

# Run tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=it_kb
```

## Troubleshooting

### "Could not generate embedding" Error

Ollama is not running. Start it with:

```bash
# Using Homebrew services
brew services start ollama

# Or run manually
ollama serve
```

### "No results found"

1. Check if articles are indexed: `it-kb --list`
2. If empty, index sample articles: `it-kb --index ./kb/sample-articles/`
3. Verify Ollama is running: `curl http://localhost:11434/api/tags`

### Slow Search Performance

- Ensure Ollama is running locally (not remote)
- First search after startup may be slower (embedding cache builds up)
- Check Ollama model is loaded: `ollama ps`

### Database Locked

Close any other instances of the CLI and try again. The database is single-writer.

### macOS-Specific Issues

#### "it-kb: command not found" after pip install

Your pip bin directory might not be in PATH:

```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="$HOME/Library/Python/3.11/bin:$PATH"

# Or use python -m
python3 -m it_kb --help
```

#### Permission Denied when indexing

Check directory permissions:
```bash
ls -la ~/.config/it-kb/
# Should be owned by your user
```

## Building for Distribution

### Homebrew Formula

```bash
# Test formula locally
brew install --build-from-source ./Formula/it-kb.rb

# Uninstall
brew uninstall it-kb
```

### Python Package

```bash
# Build wheel
python3 -m build

# The wheel will be in:
#   dist/it_knowledge_cli-1.0.0-py3-none-any.whl
```

## macOS vs Windows Differences

| Feature | macOS | Windows |
|---------|-------|---------|
| Config Path | `~/.config/it-kb/` | `%APPDATA%\it-kb\` |
| EOF Signal | Ctrl+D | Ctrl+Z + Enter |
| Ollama Install | `brew install ollama` | Download from ollama.com |
| Package Manager | Homebrew | PyInstaller (.exe) |

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Roadmap

- [ ] Web UI for article management
- [ ] Confluence/SharePoint sync connector
- [ ] Multi-language support
- [ ] Ticket system integration
- [ ] Auto-suggest based on ticket content
- [ ] iCloud sync for KB database
