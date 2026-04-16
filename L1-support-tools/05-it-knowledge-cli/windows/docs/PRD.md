# IT Knowledge CLI — PRD (Windows)

## 1. Concept & Vision

An offline-capable Q&A CLI for L1 support that answers common IT questions — "how do I reset an Outlook profile?", "what's the VPN configuration for Windows?" — instantly without leaving the terminal or making a Google search. Uses a local embeddings database so ticket data never leaves the network.

Target feel: having a senior IT engineer on the team who responds in 200ms.

## 2. Functional Spec

### 2.1 Usage

```powershell
it-kb "reset outlook profile"
it-kb "vpn configuration windows"
it-kb "how do I set up 2FA for EntraID"
it-kb --list                    # show all indexed topics
it-kb --add "2FA setup guide"   # add a new KB article
it-kb --index C:\kb-articles\   # index all markdown files from a directory
it-kb "outlook freezing" --top 3  # return top 3 results
```

### 2.2 Output

```
it-kb "reset outlook profile"

Top 1 (similarity: 0.94):
KB-2041 — Reset Outlook Profile (Windows 10/11)
================================================================
Steps to reset an Outlook profile on Windows:

1. Close Outlook completely
2. Open Control Panel → Mail (Microsoft Outlook)
3. Select Profiles → Show Profiles
4. Choose the affected profile → Remove
5. Click "Add" and re-enter the account details
6. Restart Outlook

Related: KB-2042 (IMAP setup), KB-1045 (PST file recovery)
```

### 2.3 Indexing

Index markdown files from a directory:

```powershell
it-kb --index C:\kb-articles\
it-kb --index C:\kb-articles\ --category "password"  # tag all with category
```

Each file becomes one or more KB entries. Frontmatter is parsed:

```markdown
---
id: KB-2041
title: Reset Outlook Profile
category: email
products: [outlook, microsoft-365]
last_updated: 2024-02-01
---
```

### 2.4 Embedding Model

- **Embedding:** Ollama with `nomic-embed-text` or local embedding model
- **Vector DB:** SQLite with `sqlite-vss` extension — zero external services
- **Index storage:** `%APPDATA%\it-kb\index.db`

### 2.5 Search Strategy

1. Embed query with Ollama (local, no API call to external services)
2. Vector similarity search in SQLite
3. Return top-N results with similarity score
4. Rank by: similarity score + recency weight (if `last_updated` in frontmatter)

### 2.6 Optional Online Fallback

`--search-web` flag: if local KB returns no results above threshold, optionally fall back to web search (requires API key).

## 3. Technical Approach

- **Language:** Python 3.10+
- **CLI framework:** Click
- **Embedding:** Ollama at `http://localhost:11434` (or OpenAI-compatible endpoint)
- **Vector DB:** `sqlite-vss` + standard `sqlite3`
- **Config:** `%APPDATA%\it-kb\config.yaml`
- **Doc parsing:** `python-frontmatter` + `mistune`

### File Structure

```
it-knowledge-cli/
├── pyproject.toml
├── it_kb/
│   ├── __init__.py
│   ├── __main__.py
│   ├── indexer.py
│   ├── search.py
│   ├── config.py
│   └── parser.py
├── kb/
├── tests/
│   └── test_search.py
├── build/
│   └── it-kb.exe
└── README.md
```

## 4. Success Criteria

- [ ] `it-kb "query"` returns results in < 500ms (local embeddings)
- [ ] Index persists across sessions (`%APPDATA%\it-kb\index.db`)
- [ ] `--add` inserts new article and re-indexes
- [ ] `--index` ingests directory of markdown files with frontmatter
- [ ] `--list` shows all indexed KB articles with categories
- [ ] Works fully offline after initial index
- [ ] Relevant results for "reset password" returns EntraID and AD password reset articles

## 5. Out of Scope (v1)

- Web UI
- Ticket system integration
- Multi-language articles
- Auto-sync from Confluence/SharePoint (future connector)
- Non-markdown file formats
