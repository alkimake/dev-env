# Personal Dev-Env examples

This repo includes nix and direnv configurations i use personally. Please feel free to open a ticket or PR


## Usage

On samples I used `devops` as an example. Please change it with other dev envrionments exists as sub-directories in this repo.
Direct usage of dev-env can be either following ways;

### Using nix

```sh
nix develop github:alkimake/dev-env?dir=devops
```

### Using direnv

```sh
# Create .envrc file with the content above
echo 'use flake github:alkimake/dev-env?dir=devops' > .envrc
direnv allow
```

:warning: the rest of the `.envrc` file should be included for the same direnv behaviour


### Using flake

You can edit your flake.nix by including as an input 

```nix
{
  description = "Your project description";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    devenv.url = "github:alkimake/dev-env?dir=devops";
  };

  outputs = { self, nixpkgs, devenv }: {
    # Use the development shell from devenv
    devShells = devenv.devShells;

    # Or extend it with additional packages
    devShells = forEachSupportedSystem ({pkgs}: {
      default = devenv.devShells.${system}.default.overrideAttrs (oldAttrs: {
        packages = oldAttrs.packages ++ [
          # Add your additional packages here
          pkgs.some-package
        ];
      });
    });
  };
}
```
