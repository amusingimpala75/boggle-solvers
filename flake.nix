{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }({...}: {
    systems = inputs.nixpkgs.lib.systems.flakeExposed;
    perSystem = { pkgs, ... }: {
      devShells.default = pkgs.mkShell {
        packages = [
          # Tools
          pkgs.just
          pkgs.hyperfine
          # Rust
          pkgs.cargo pkgs.rustc pkgs.rust-analyzer
          # Go
          pkgs.go pkgs.gopls
          # Haskell
          pkgs.ghc pkgs.haskell-language-server
        ];
      };
    };
  });
}
