"""CLI entry point for IT Knowledge CLI (macOS)."""

import click
import sys
from .indexer import index_directory, add_article, list_articles
from .search import search, get_article


@click.command()
@click.argument("query", required=False)
@click.option("--list", "show_list", is_flag=True, help="Show all indexed articles")
@click.option("--add", "add_title", help="Add a new KB article (provide title)")
@click.option("--index", "index_path", help="Index markdown files from directory")
@click.option("--category", help="Category for --add or --index")
@click.option("--top", default=3, help="Number of results (default: 3)")
@click.option("--id", "article_id", help="Show specific article by ID")
@click.version_option(version="1.0.0", prog_name="it-kb")
def cli(query, show_list, add_title, index_path, category, top, article_id):
    """IT Knowledge CLI - Offline Q&A for L1 support.

    Search the local knowledge base using natural language queries.
    Requires Ollama running at localhost:11434 for embeddings.

    Examples:

        it-kb "reset outlook profile"

        it-kb "vpn dns" --top 5

        it-kb --list

        it-kb --index ./kb-articles/

        it-kb --add "New Article Title" --category "networking"
    """
    # Handle --index
    if index_path:
        count = index_directory(index_path, category)
        click.echo(f"Indexed {count} articles from {index_path}")
        return

    # Handle --add
    if add_title:
        click.echo(f"Adding article: {add_title}")
        click.echo("Enter content (Ctrl+D when done):")

        # Read multi-line content (Unix/macOS uses Ctrl+D for EOF)
        lines = []
        try:
            while True:
                line = input()
                lines.append(line)
        except EOFError:
            pass

        content = "\n".join(lines)
        if not content.strip():
            click.echo("Error: No content provided", err=True)
            sys.exit(1)

        new_id = add_article(add_title, content, category or "")
        if new_id:
            click.echo(f"Added article: {new_id}")
        else:
            click.echo("Error: Could not add article. Is Ollama running?", err=True)
            sys.exit(1)
        return

    # Handle --list
    if show_list:
        articles = list_articles(category)
        if not articles:
            click.echo("No articles indexed. Use --index to add articles.")
            return

        click.echo(f"{'ID':<12} {'Category':<15} {'Title'}")
        click.echo("-" * 60)
        for article in articles:
            cat = article["category"] or "-"
            click.echo(f"{article['id']:<12} {cat:<15} {article['title']}")
        click.echo(f"\nTotal: {len(articles)} articles")
        return

    # Handle --id
    if article_id:
        article = get_article(article_id)
        if article:
            click.echo(f"\n{article['id']} — {article['title']}")
            click.echo("=" * 60)
            if article["category"]:
                click.echo(f"Category: {article['category']}")
            if article["last_updated"]:
                click.echo(f"Updated: {article['last_updated']}")
            click.echo()
            click.echo(article["content"])
        else:
            click.echo(f"Article not found: {article_id}", err=True)
            sys.exit(1)
        return

    # Handle query
    if query:
        results = search(query, top)

        if not results:
            click.echo("No results found.")
            click.echo(
                "Tip: Use --index to add articles, or check if Ollama is running."
            )
            return

        for i, r in enumerate(results, 1):
            click.echo(f"\nTop {i} (similarity: {r['similarity']:.2f}):")
            click.echo(f"{r['id']} — {r['title']}")
            if r["category"]:
                click.echo(f"Category: {r['category']}")
            click.echo("=" * 60)

            # Show content (first 500 chars)
            content = r["content"][:500]
            if len(r["content"]) > 500:
                content += "..."
            click.echo(content)
        return

    # No arguments provided
    click.echo(cli.get_help(click.Context(cli)))


if __name__ == "__main__":
    cli()
