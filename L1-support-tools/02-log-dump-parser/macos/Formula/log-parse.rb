class LogParse < Formula
  include Language::Python::Virtualenv

  desc "CLI tool for parsing and analyzing log files"
  homepage "https://github.com/mchael/log-parse"
  url "https://github.com/mchael/log-parse/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "python@3.10"

  resource "click" do
    url "https://files.pythonhosted.org/packages/b9/2e/0090cbf739cee7d23781ad4b89a9894a41538e4fcf4c31dcdd705b78eb8b/click-8.1.8.tar.gz"
    sha256 "ed53c9d8990d83c2a27deae68e4ee337473f6330c040a31d4225c9574d16096a"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/54/ed/79a089b6be93607fa5cdaedf301d7dfb23af5f25c398d5ead2525b063e17/pyyaml-6.0.2.tar.gz"
    sha256 "d584d9ec91ad65861cc08d42e834324ef890a082e591037abe114850ff7abc3e"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    # Create a test log file
    (testpath/"test.log").write "Jan 15 10:30:45 server test: Error message\n"
    
    # Run the tool
    output = shell_output("#{bin}/log-parse #{testpath/"test.log"}")
    assert_match "Log Summary", output
    assert_match "Errors: 1", output
  end
end
