# typed: false
# frozen_string_literal: true

# Runbook Automation CLI
# Execute markdown-based runbooks with embedded shell commands

class Runbook < Formula
  desc "CLI tool for managing and executing markdown-based runbooks"
  homepage "https://github.com/example/runbook-automation"
  url "https://github.com/example/runbook-automation/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/example/runbook-automation.git", branch: "main"

  depends_on "python@3.10"

  resource "click" do
    url "https://files.pythonhosted.org/packages/96/d3/f04c7bfcf5c1862a2a5b845c6b2b360488cf47af55dfa79c98f6a6bf98b5/click-8.1.7.tar.gz"
    sha256 "ca9853ad459e787e2192211578cc907e7594e294c7ccc834310722b41b9ca6de"
  end

  resource "mistune" do
    url "https://files.pythonhosted.org/packages/2c/33/0ce0c8a4c72842434636c6e0282e6c508f2595a2d8d9455c1f43d9f15dc2/mistune-3.0.2.tar.gz"
    sha256 "fc7fcc95fc1b7b3e1f66adaa3442d4f2277fc58cd62c214e6565ade776fe90b5"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    # Create a simple test runbook
    (testpath/"test.md").write <<~EOS
      # Test Runbook

      ```bash
      echo "Hello, World!"
      ```
    EOS

    # Test CLI commands
    assert_match "Hello, World!", shell_output("#{bin}/runbook run #{testpath}/test.md --dry-run")
    assert_match "Total steps: 1", shell_output("#{bin}/runbook run #{testpath}/test.md --show-steps")
    assert_match "test", shell_output("#{bin}/runbook list --directory #{testpath}")
  end
end
