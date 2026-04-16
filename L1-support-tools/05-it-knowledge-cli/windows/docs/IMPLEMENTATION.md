# IT Knowledge CLI — Implementation Plan (Windows)

## 1. Project Setup

```powershell
cd it-knowledge-cli
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install click python-frontmatter mistune sqlite-vss pyinstaller
```

## 2. File Structure

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
│   └── sample-articles/
├── tests/
│   └── test_search.py
├── build/
│   └── it-kb.exe
├── it-kb.spec
└── README.md
```

---

## 3. Core Architecture

### 3.1 config.py (Windows paths)

```python
import os
from pathlib import Path

def get_config_path() -> Path:
    appdata = os.environ.get('APPDATA', Path.home() / 'AppData' / 'Roaming')
    return Path(appdata) / 'it-kb'

def get_index_path() -> Path:
    return get_config_path() / 'index.db'

def ensure_config_dir():
    get_config_path().mkdir(parents=True, exist_ok=True)
```

### 3.2 indexer.py

```python
import frontmatter
import sqlite3
from pathlib import Path
from .config import get_index_path, ensure_config_dir

def init_db():
    ensure_config_dir()
    conn = sqlite3.connect(get_index_path())
    conn.enable_load_extension(True)
    # Load sqlite-vss extension
    conn.load_extension('sqlite_vss')
    
    conn.execute('''
        CREATE TABLE IF NOT EXISTS articles (
            id TEXT PRIMARY KEY,
            title TEXT,
            category TEXT,
            content TEXT,
            embedding BLOB,
            last_updated TEXT
        )
    ''')
    return conn

def index_directory(directory: str, category: str = None):
    conn = init_db()
    for path in Path(directory).rglob('*.md'):
        with open(path) as f:
            article = frontmatter.load(f)
        
        content = article.content
        metadata = dict(article)
        
        if category:
            metadata['category'] = category
        
        embedding = get_embedding(content)
        
        conn.execute('''
            INSERT OR REPLACE INTO articles 
            (id, title, category, content, embedding, last_updated)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            metadata.get('id', path.stem),
            metadata.get('title', path.stem),
            metadata.get('category', ''),
            content,
            embedding,
            metadata.get('last_updated', '')
        ))
    
    conn.commit()
    conn.close()

def get_embedding(text: str) -> bytes:
    import requests
    resp = requests.post(
        'http://localhost:11434/api/embeddings',
        json={'model': 'nomic-embed-text', 'prompt': text}
    )
    return bytes(resp.json()['embedding'])
```

### 3.3 search.py

```python
import sqlite3
from .config import get_index_path
from .indexer import get_embedding

def search(query: str, top_n: int = 3) -> list[dict]:
    conn = sqlite3.connect(get_index_path())
    conn.enable_load_extension(True)
    conn.load_extension('sqlite_vss')
    
    query_embedding = get_embedding(query)
    
    cursor = conn.execute('''
        SELECT id, title, category, content, 
               vss_distance(embedding, ?) as distance
        FROM articles
        ORDER BY distance ASC
        LIMIT ?
    ''', (query_embedding, top_n))
    
    results = []
    for row in cursor.fetchall():
        results.append({
            'id': row[0],
            'title': row[1],
            'category': row[2],
            'content': row[3],
            'similarity': 1 - row[4]
        })
    
    conn.close()
    return results
```

---

## 4. CLI (Click)

```python
# __main__.py
import click

@click.command()
@click.argument('query', required=False)
@click.option('--list', 'show_list', is_flag=True)
@click.option('--add', help='Add a new KB article')
@click.option('--index', help='Index markdown files from directory')
@click.option('--top', default=3, help='Number of results')
def cli(query, show_list, add, index, top):
    if index:
        from .indexer import index_directory
        index_directory(index)
        click.echo(f"Indexed {index}")
    elif query:
        from .search import search
        results = search(query, top)
        for i, r in enumerate(results, 1):
            click.echo(f"\nTop {i} (similarity: {r['similarity']:.2f}):")
            click.echo(f"{r['id']} — {r['title']}")
            click.echo("=" * 60)
            click.echo(r['content'][:500])
    else:
        click.echo("Use: it-kb <query>")

if __name__ == '__main__':
    cli()
```

---

## 5. Windows Build

```powershell
# Build standalone executable
pyinstaller it-kb.spec

# it-kb.spec
a = Analysis(
    ['it_kb/__main__.py'],
    datas=[('kb/*.md', 'kb'), ('sqlite_vss.dll', '.')],
    hiddenimports=['sqlite3'],
    name='it-kb',
    console=True
)
```

---

## 6. Known Pitfalls (Windows)

1. **sqlite-vss extension** — Need to bundle DLL with executable
2. **Ollama** — Must be installed separately on Windows
3. **Path lengths** — Windows has 260 char path limit (use UNC paths)
4. **Permissions** — `%APPDATA%` should be writable

---

## 7. Out of Scope

- Web UI
- Multi-language support
- Confluence/SharePoint sync
