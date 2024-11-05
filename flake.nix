{
  description = "A Nix-flake-based development environment for AWS, Terraform, and Kubernetes";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: let
      # Create a wrapper for Naver Cloud CLI
      ncloud-cli = pkgs.stdenv.mkDerivation {
        name = "ncloud-cli";
        version = "1.1.22"; # Current latest version

        src = pkgs.fetchurl {
          url = "https://www.ncloud.com/api/support/download/files/cli/CLI_1.1.22_20241017.zip";
          sha256 = "sha256-GndRqHNzz/DP1ppqOjMAYlSWTeAbt8TTVxk8wTC1CIM=";
        };

        buildInputs = with pkgs; [makeWrapper jdk unzip];

        unpackPhase = ''
          unzip $src
        '';

        installPhase = ''
          mkdir -p $out/bin $out/lib
          cp CLI_1.1.22_20241017/cli_linux/lib/ncloud-api-cli-1.1.22-SNAPSHOT-jar-with-dependencies.jar $out/lib/ncloud-cli.jar
          makeWrapper ${pkgs.jdk}/bin/java $out/bin/ncloud \
            --add-flags "-jar $out/lib/ncloud-cli.jar"
        '';
      };

      # Create a derivation for ncp-iam-authenticator
      ncp-iam-authenticator = pkgs.buildGoModule {
        pname = "ncp-iam-authenticator";
        version = "1.0"; # Update version as needed

        src = pkgs.fetchFromGitHub {
          owner = "NaverCloudPlatform";
          repo = "ncp-iam-authenticator";
          rev = "main"; # Or specific tag/commit
          sha256 = "sha256-tgtu5UlKXbFaEtmtfWecLlGueWTiJTWETu9vAuO0AmE=";
        };

        vendorHash = "sha256-CPK3knKHVSKm8oEj+/WeAE0uL3/DThsycj+hA8zpDbM=";

        # If the program outputs version info differently, adjust this
        checkPhase = ''
          $GOPATH/bin/ncp-iam-authenticator version || true
        '';

        meta = with pkgs.lib; {
          description = "A tool to use Naver Cloud Platform IAM credentials to authenticate to a Kubernetes cluster";
          homepage = "https://github.com/NaverCloudPlatform/ncp-iam-authenticator";
          license = licenses.asl20;
          maintainers = [];
          platforms = platforms.unix;
        };
      };
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          # Terraform and related tools
          terraform
          tflint
          terragrunt

          # AWS CLI and related tools
          awscli2
          aws-iam-authenticator
          ssm-session-manager-plugin

          # Kubernetes tools
          kubectl
          kubernetes-helm
          k9s
          stern

          # Additional useful tools
          jq # JSON processor
          yq-go # YAML processor
          eksctl # EKS cluster management
          lens # Kubernetes IDE

          # Development tools
          pre-commit
          shellcheck

          # Naver Cloud CLI and dependencies
          jdk
          ncloud-cli
          ncp-iam-authenticator
        ];

        shellHook = ''
          # Add any environment setup here
          echo "AWS Terraform Development Environment"
          echo "Available tools:"
          echo "- AWS CLI $(aws --version | cut -d ' ' -f1)"
          echo "- Terraform $(terraform version | head -n1)"
          echo "- Kubectl $(kubectl version --client | grep 'Client Version' || kubectl version --client --short)"
          echo "- Helm $(helm version --short)"
          echo "- Naver Cloud CLI $(ncloud --version | head -n1)"
          echo "- NCP IAM Authenticator $(ncp-iam-authenticator version || echo 'version unknown')"
        '';
      };
    });
  };
}
