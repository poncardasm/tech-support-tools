class DiagCollect < Formula
  desc "System diagnostic collector for macOS L1/L2 support"
  homepage "https://github.com/mchael/L1-support-tools"
  url "https://github.com/mchael/L1-support-tools/archive/refs/heads/main.tar.gz"
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "python@3.12"

  resource "click" do
    url "https://files.pythonhosted.org/packages/source/c/click/click-8.1.7.tar.gz"
    sha256 "ca9853ad459e787e2192211578cc907e7594e294c7ccc834310722b41b9ca6de"
  end

  def install
    # Install Python dependencies
    venv = virtualenv_create(libexec, "python3.12")
    
    resource("click").stage do
      system libexec/"bin/pip", "install", *std_pip_args, "."
    end

    # Install the package
    venv.pip_install_and_link buildpath/"04-diagnostic-collector/macos"

    # Install the collector.sh script
    bin.install "04-diagnostic-collector/macos/diag/collector.sh" => "diag-collect-legacy"

    # Create wrapper script that sets up environment
    (bin/"diag-collect").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{libexec}/lib/python3.12/site-packages:$PYTHONPATH"
      exec "#{libexec}/bin/python" -m diag "$@"
    EOS
    chmod 0755, bin/"diag-collect"
  end

  test do
    # Test that the command runs
    system "#{bin}/diag-collect", "--help"
    
    # Test that collector.sh is executable
    assert_predicate bin/"diag-collect-legacy", :executable?
  end
end
