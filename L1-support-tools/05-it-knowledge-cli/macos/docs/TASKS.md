# IT Knowledge CLI — Tasks (macOS)

## Phase 1: Project Skeleton

- [x] Create `pyproject.toml` with dependencies
- [x] Create `it_kb/__init__.py`
- [x] Create `it_kb/__main__.py`
- [x] Create `tests/test_search.py`
- [x] Verify `pip install -e .` works

---

## Phase 2: Vector Database Setup

- [x] Install sqlite-vec extension
- [x] Implement `init_db()` function
- [x] Create articles table schema
- [x] Test database creation in `~/.config/it-kb/`

---

## Phase 3: Embeddings

- [x] Integrate Ollama for embeddings
- [x] Implement `get_embedding()` function
- [x] Handle Ollama unavailability gracefully
- [x] Test embedding generation

---

## Phase 4: Indexing

- [x] Implement `index_directory()` function
- [x] Parse markdown with frontmatter
- [x] Extract metadata
- [x] Store embeddings in SQLite

---

## Phase 5: Search

- [x] Implement `search()` function
- [x] Vector similarity search
- [x] Return top-N results
- [x] Format output for display

---

## Phase 6: CLI

- [x] Implement main Click command
- [x] `--list` to show all articles
- [x] `--add` to add new article
- [x] `--index` to index directory
- [x] `--top N` for result count

---

## Phase 7: Testing

- [x] Create test fixtures
- [x] Test indexing
- [x] Test search
- [x] Test embedding fallback

---

## Phase 8: Homebrew Packaging

- [x] Create `Formula/it-kb.rb`
- [x] Document Homebrew installation

---

## Phase 9: Documentation

- [x] Write `README.md`
- [x] Document Ollama setup on macOS
- [x] Add usage examples
- [x] Document macOS-specific differences

---

## Phase 10: Publish

- [x] Push to GitHub (via monorepo)
- [x] All phases committed
- [ ] Optional: Homebrew tap publishing
- [ ] Optional: PyPI
