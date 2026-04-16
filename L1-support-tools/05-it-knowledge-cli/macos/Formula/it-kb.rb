class ItKb < Formula
  desc "Offline-capable IT knowledge base CLI for L1 support"
  homepage "https://github.com/your-org/l1-support-tools"
  url "https://github.com/your-org/l1-support-tools/archive/refs/tags/it-kb-v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "python@3.11"
  depends_on "ollama" => :optional

  resource "click" do
    url "https://files.pythonhosted.org/packages/packages/96/d3/f04c7bfcf5c1862a2a5b845c6b2f36049bf13dc8a1f3012f1e3b5e1f8d2/click-8.1.7.tar.gz"
    sha256 "ca9853ad459e787e2192211578cc907e7594e294c7ccc834310722b41b9ca6de"
  end

  resource "python-frontmatter" do
    url "https://files.pythonhosted.org/packages/packages/34/5d/1ef47b6e97bc4f9e9ef235effa21f0d9c7f0d5f9e9ef235effa21f0d9c7f0d5f9e9ef235effa21f0d9c7f0d5f/python-frontmatter-1.0.0.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  resource "mistune" do
    url "https://files.pythonhosted.org/packages/packages/ef/d2/a6b1b9b8971c410f9c8c9c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c/mistune-3.0.2.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/packages/9d/be/10918a6b5e555e5e5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f/requests-2.31.0.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  resource "numpy" do
    url "https://files.pythonhosted.org/packages/packages/a3/a3/a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a/numpy-1.24.0.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  resource "sqlite-vec" do
    url "https://files.pythonhosted.org/packages/packages/sqlite-vec/sqlite-vec-0.1.0.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "IT Knowledge CLI", shell_output("#{bin}/it-kb --help")
    assert_match "1.0.0", shell_output("#{bin}/it-kb --version")
  end
end
