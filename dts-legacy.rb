# typed: false
# frozen_string_literal: true

class DtsLegacy < Formula
  desc "Legacy DTS CLI - Data testing framework (v0.18.x, replaced by DTS v2)"
  homepage "https://bigtimedata.io/"
  version "0.18.0"
  depends_on :macos

  on_intel do
    url "https://github.com/Big-Time-Data/homebrew-dts/releases/download/v0.18.0/dts_darwin_amd64.tar.gz"
    sha256 "6924de2bc4c75227f618f99186a282d5099539580eff67c3db0e4501fbc90ebb"

    def install
      bin.install "dts" => "dts-legacy"
    end
  end

  on_arm do
    url "https://github.com/Big-Time-Data/homebrew-dts/releases/download/v0.18.0/dts_darwin_arm64.tar.gz"
    sha256 "ec2988663d99702ca373926c1e186f3d5f0f9935d3db9978274998f3b0cfed73"

    def install
      bin.install "dts" => "dts-legacy"
    end
  end

  def caveats
    <<~EOS
      This is the LEGACY version of DTS (v0.18.x).
      The binary is installed as 'dts-legacy' to avoid conflicts.

      For the new DTS with web UI and Claude integration:
        brew install Big-Time-Data/dts/dts
    EOS
  end
end
