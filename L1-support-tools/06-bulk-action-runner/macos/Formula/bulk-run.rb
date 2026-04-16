class BulkRun < Formula
  desc "CSV-powered bulk operations tool for L1 support"
  homepage "https://github.com/L1-support-tools/bulk-action-runner"
  url "https://github.com/L1-support-tools/bulk-action-runner/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "python@3.10"

  resource "click" do
    url "https://files.pythonhosted.org/packages/packages/click/click-8.1.7.tar.gz"
    sha256 "ca9853ad459e787e2192211578cc907e7594e294c7ccc834310722b41b9ca6de"
  end

  resource "msgraph-sdk" do
    url "https://files.pythonhosted.org/packages/packages/msgraph-sdk/msgraph-sdk-1.0.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "azure-identity" do
    url "https://files.pythonhosted.org/packages/packages/azure-identity/azure-identity-1.14.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "python-dotenv" do
    url "https://files.pythonhosted.org/packages/packages/python-dotenv/python-dotenv-1.0.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    system "#{bin}/bulk-run", "--help"
  end
end
