{ pkgs, lib, ... }:


let
  # Fully persisted and backed up links
  mkPersistentLink = path: pkgs.runCommand "persistent-link" {} ''
    ln -s /nix/persistent/adisbladis/${path} $out
  '';

  findGitRecursive = root: let
    files = builtins.readDir root;
    dirs = lib.filterAttrs (k: v: v == "directory") files;
    repoSet = lib.mapAttrs (k: v: builtins.pathExists (root + "/${k}/.git")) dirs;
    repos = builtins.map (v: builtins.toString (root + "/${v}")) (lib.attrNames (lib.filterAttrs (k: v: v) repoSet));
    notRepos = lib.attrNames (lib.filterAttrs (k: v: !v) repoSet);
    nestedRepos = builtins.foldl' (a: v: a ++ findGitRecursive (root + "/${v}")) [] notRepos;
  in repos ++ nestedRepos;

in {

  # Home files with persistency
  home.file.".password-store".source = mkPersistentLink ".password-store";
  home.file.".local/share/fish".source = mkPersistentLink ".local/share/fish";
  home.file.".mozilla/firefox".source = mkPersistentLink ".mozilla/firefox";

  # Data storage directories
  home.file."Downloads".source = mkPersistentLink "Downloads";
  home.file."Music".source = mkPersistentLink "Music";
  home.file."Documents".source = mkPersistentLink "Documents";
  home.file."Vids".source = mkPersistentLink "Vids";
  home.file."sauce".source = mkPersistentLink "sauce";

  imports = [
    ./desktop.nix
  ];

  nixpkgs.overlays = [
    (import ../overlays/exwm-overlay)
  ];

  home.packages = with pkgs; let
    ipythonEnv = (python3.withPackages (ps: [
      ps.ipython
      ps.requests
      ps.psutil
      ps.nixpkgs
    ]));
    # Link into ipythonEnv package to avoid polluting $PATH with python deps
    ipythonPackage = pkgs.runCommand "ipython-stripped" {} ''
      mkdir -p $out/bin
      ln -s ${ipythonEnv}/bin/ipython $out/bin/ipython
    '';
  in [
    ipythonPackage
    wgetpaste
    nix-review
    traceroute
    ripgrep
    ag
    whois
    nmap
    unzip
    zip
  ];

  # Fish config
  home.file.".config/fish/functions/fish_prompt.fish".source = ./dotfiles/fish/functions/fish_prompt.fish;
  # home.file.".config/fish/functions/fish_right_prompt.fish".source = ./dotfiles/fish/functions/fish_right_prompt.fish;

  home.sessionVariables.LESS = "-R";

  programs.direnv.enable = true;

  programs.fish = {
    enable = true;
    shellAliases = with pkgs; {
      pcat = "${python3Packages.pygments}/bin/pygmentize";
    };
  };

  # services.hound = {
  #   enable = true;
  #   repositories = lib.listToAttrs (builtins.map (v: {
  #     name = builtins.baseNameOf v;
  #     value = { url = "file://" + v; };
  #   }) (findGitRecursive /home/adisbladis/sauce));
  # };

  programs.git = {
    enable = true;
    userName = "adisbladis";
    userEmail = "adisbladis@gmail.com";
    signing.key = "00244EF5295026AA323A4BDB110BFAD44C6249B7";
  };

  manual.manpages.enable = false;
}
