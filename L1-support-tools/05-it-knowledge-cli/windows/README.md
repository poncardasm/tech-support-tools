# IT Knowledge CLI (Windows)

An offline-capable Q&A CLI for L1 support that answers common IT questions instantly without leaving the terminal or making a Google search. Uses a local embeddings database so ticket data never leaves the network.

**Target feel:** having a senior IT engineer on the team who responds in 200ms.

## Features

- **Offline-first**: Works without internet after initial setup
- **Vector search**: Uses embeddings for semantic similarity matching
- **Local LLM**: Integrates with Ollama for local embedding generation
- **Fast**: Returns results in under 500ms
- **Markdown support**: Index KB articles with YAML frontmatter
- **Windows native**: Stores data in `%APPDATA%\it-kb\`

## Prerequisites

1. **Python 3.10+** - [Download from python.org](https://python.org)
2. **Ollama** - Local LLM runner for embeddings

### Installing Ollama on Windows

1. Download Ollama from [ollama.com](https://ollama.com)
2. Run the installer
3. Pull the embedding model:
   ```powershell
   ollama pull nomic-embed-text
   ```
4. Verify Ollama is running:
   ```powershell
   ollama list
   ```

## Installation

### Option 1: From Source (Development)

```powershell
# Clone or navigate to the project
cd 05-it-knowledge-cli\windows

# Create virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install in development mode
pip install -e .

# Verify installation
it-kb --help
```

### Option 2: Standalone Executable

Build a standalone `.exe` using PyInstaller:

```powershell
# Install dev dependencies
pip install pyinstaller

# Build executable
pyinstaller it-kb.spec

# The executable will be in dist\it-kb.exe
.\dist\it-kb.exe --help
```

## Quick Start

### 1. Index Sample Articles

```powershell
# Index the included sample KB articles
it-kb --index .\kb\sample-articles\

# You should see:
# Indexed: KB-1001 — Set Up 2FA for Microsoft Entra ID
# Indexed: KB-1045 — PST File Recovery and Repair
# Indexed: KB-2041 — Reset Outlook Profile (Windows 10/11)
# Indexed: KB-3001 — VPN DNS Override Configuration (Windows)
```

### 2. Search the Knowledge Base

```powershell
# Search for Outlook issues
it-kb "reset outlook profile"

# Search with more results
it-kb "vpn dns" --top 5

# Search for 2FA setup
it-kb "how do I set up 2FA"
```

### 3. List All Articles

```powershell
it-kb --list
```

## Usage

### Search Commands

```powershell
# Basic search
it-kb "your search query"

# Get top 5 results instead of default 3
it-kb "password reset" --top 5

# Show specific article by ID
it-kb --id KB-2041
```

### Indexing Commands

```powershell
# Index a directory of markdown files
it-kb --index C:\path\to\kb-articles\

# Index with a specific category
it-kb --index C:\kb\ --category "networking"

# List all indexed articles
it-kb --list

# List articles in a specific category
it-kb --list --category "email"
```

### Adding New Articles

```powershell
# Add a new article interactively
it-kb --add "Article Title" --category "category"

# Then type your content and press Ctrl+Z followed by Enter
```

## Article Format

KB articles are Markdown files with YAML frontmatter:

```markdown
---
id: KB-2041
title: Reset Outlook Profile (Windows 10/11)
category: email
products: [outlook, microsoft-365]
last_updated: 2024-02-01
---

# Reset Outlook Profile (Windows 10/11)

Steps to reset an Outlook profile on Windows:

1. Close Outlook completely
2. Open Control Panel → Mail (Microsoft Outlook)
3. Select Profiles → Show Profiles
4. Choose the affected profile → Remove
5. Click "Add" and re-enter the account details
6. Restart Outlook
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
%APPDATA%\it-kb\
├── index.db          # Vector database with articles and embeddings
└── config.yaml       # Future: configuration file (not yet implemented)
```

To reset the knowledge base:

```powershell
# Delete the database (Windows)
Remove-Item "$env:APPDATA\it-kb\index.db"
```

## Sample Output

```
$ it-kb "reset outlook profile"

Top 1 (similarity: 0.94):
KB-2041 — Reset Outlook Profile (Windows 10/11)
Category: email
============================================================
# Reset Outlook Profile (Windows 10/11)

Steps to reset an Outlook profile on Windows:

1. Close Outlook completely
2. Open Control Panel → Mail (Microsoft Outlook)
3. Select Profiles → Show Profiles
4. Choose the affected profile → Remove
...
```

## Architecture

```
it-knowledge-cli/
├── it_kb/                 # Main package
│   ├── __init__.py        # Package metadata
│   ├── __main__.py        # CLI entry point (Click)
│   ├── config.py          # Windows path configuration
│   ├── embeddings.py      # Ollama embedding integration
│   ├── indexer.py         # Database and indexing logic
│   └── search.py          # Vector similarity search
├── kb/
│   └── sample-articles/   # Sample KB articles
├── tests/
│   └── test_search.py     # pytest test suite
├── pyproject.toml         # Package configuration
└── it-kb.spec             # PyInstaller build spec
```

### Technology Stack

- **CLI Framework**: Click
- **Vector Database**: SQLite with sqlite-vec extension
- **Embeddings**: Ollama (nomic-embed-text model)
- **Frontmatter Parsing**: python-frontmatter
- **Testing**: pytest

## How It Works

1. **Indexing**: Markdown files are parsed, embeddings are generated via Ollama, and both content and vectors are stored in SQLite
2. **Search**: Query is converted to embedding, vector similarity search finds closest matches
3. **Results**: Top-N articles returned with similarity scores

## Testing

Run the test suite:

```powershell
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

```powershell
ollama serve
```

### "No results found"

1. Check if articles are indexed: `it-kb --list`
2. If empty, index sample articles: `it-kb --index .\kb\sample-articles\`

### Slow Search Performance

- Ensure Ollama is running locally
- First search after startup may be slower (embedding cache builds up)

### Database Locked

Close any other instances of the CLI and try again.

## Building for Distribution

### Standalone Executable

```powershell
# Build with PyInstaller
pyinstaller it-kb.spec

# The executable will be in:
#   dist\it-kb.exe

# Test the executable
.\dist\it-kb.exe --help
```

### Python Package

```powershell
# Build wheel
python -m build

# The wheel will be in:
#   dist\it_knowledge_cli-1.0.0-py3-none-any.whl
```

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
