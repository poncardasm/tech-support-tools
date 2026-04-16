class TicketTriage < Formula
  include Language::Python::Virtualenv

  desc "CLI tool for L1 support ticket triage"
  homepage "https://github.com/poncardasm/L1-support-tools"
  url "https://github.com/poncardasm/L1-support-tools/archive/refs/tags/ticket-triage-v1.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"

  depends_on "python@3.11"

  resource "click" do
    url "https://files.pythonhosted.org/packages/source/c/click/click-8.3.2.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/source/p/pyyaml/pyyaml-6.0.3.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  def install
    # Change into the macos subdirectory where the package is located
    cd "01-ticket-triage-cli/macos" do
      virtualenv_install_with_resources
    end
  end

  test do
    # Test that the CLI works with piped input
    assert_match "Category:", pipe_output("#{bin}/ticket-triage", "User can't login to password")
    
    # Test JSON output
    output = pipe_output("#{bin}/ticket-triage --json", "VPN connection down")
    assert_match "category", output
    assert_match "priority", output
  end
end
