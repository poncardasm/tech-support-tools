class AdProvision < Formula
  desc "CLI for Azure AD/EntraID user provisioning"
  homepage "https://github.com/your-org/ad-provisioning-cli"
  url "https://github.com/your-org/ad-provisioning-cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "python@3.11"

  resource "click" do
    url "https://files.pythonhosted.org/packages/packages/b9/2e/0090cbf739cee7d23781ad4b89a9894a41538e4cd4c8c5684b01df81daea/click-8.1.8.tar.gz"
    sha256 "ed53c9d8990d83c2a27deae68e4ee337473f6330c040a31d4225c9574d16096a"
  end

  resource "msgraph-sdk" do
    url "https://files.pythonhosted.org/packages/source/m/msgraph-sdk/msgraph-sdk-1.55.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "azure-identity" do
    url "https://files.pythonhosted.org/packages/source/a/azure-identity/azure-identity-1.14.1.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "python-dotenv" do
    url "https://files.pythonhosted.org/packages/source/p/python-dotenv/python-dotenv-1.0.1.tar.gz"
    sha256 "PLACEHOLDER"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "Usage", shell_output("#{bin}/ad-provision --help")
    assert_match "new-user", shell_output("#{bin}/ad-provision --help")
    assert_match "deprovision", shell_output("#{bin}/ad-provision --help")
  end
end
