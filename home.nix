{
  # FIXME: uncomment the next line if you want to reference your GitHub/GitLab access tokens and other secrets
  # secrets,
  pkgs,
  username,
  nix-index-database,
  lib,
  config,
  ...
}: let
  # custom ruby-build package
  ruby-build = pkgs.callPackage ./pkgs/ruby-build.nix { };

  # ignore volunrability warning for deprecated openssl_1_1
  ignoringVulns = x: x // { meta = (x.meta // { knownVulnerabilities = []; }); };
  openssl1_1 = pkgs.openssl_1_1.overrideAttrs ignoringVulns;

  # list libraries paths for compilation of Ruby 
  libPath = lib.makeLibraryPath [
    openssl1_1.out
    pkgs.glibc
    pkgs.zlib
  ];

  unstable-packages = with pkgs.unstable; [
    bat
    bottom
    coreutils
    curl
    du-dust
    fd
    findutils
    git
    fx
    lazygit
    git-crypt
    htop
    jq
    killall
    mosh
    procs
    ripgrep
    sd
    tmux
    tree
    unzip
    neovim
    vim
    wget
    zip
    devenv 
  ];

  stable-packages = with pkgs; [
    # key tools
    gh # for bootstrapping
    git-credential-manager
    just

    # core languages
    # rustup
    gcc
    lua
    go 
    cargo
    nodejs_22
    ruby
    python3

    # ruby related 
    ruby-build
    rbenv
    openssl1_1
    zlib
 
    bison
    flex
    fontforge
    makeWrapper
    pkg-config
    gnumake
    gcc
    libiconv
    autoconf
    automake
    libtool

    # rust stuff
    cargo-cache
    cargo-expand

    # local dev stuf
    mkcert
    httpie

    # treesitter
    tree-sitter

    # language servers
    nodePackages.vscode-langservers-extracted # html, css, json, eslint
    nodePackages.yaml-language-server
    nil # nix

    # formatters and linters
    alejandra # nix
    deadnix # nix
    nodePackages.prettier
    shellcheck
    shfmt
    statix # nix

    atuin
    nh
  ];
in {
  imports = [
    nix-index-database.hmModules.nix-index
  ];

  home.stateVersion = "22.11";

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";

    sessionVariables.EDITOR = "nvim";
    sessionVariables.LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:${libPath}";
    sessionVariables.C_INCLUDE_PATH = "${openssl1_1.dev.outPath}/include:${pkgs.zlib.dev.outPath}/include";
    sessionVariables.SHELL = "/etc/profiles/per-user/${username}/bin/fish";
    sessionVariables.FLAKE = "/home/andrzejsliwa/configuration";
  };

  home.packages =
    stable-packages
    ++ unstable-packages
    ++
    [
      # pkgs.some-package
      # pkgs.unstable.some-other-package
    ];

  # home.file = {
  #   ".config/nvim" = {
  #    source = config.lib.file.mkOutOfStoreSymlink ./nvim;
  #  };
  #};
  programs.neovim = {
    enable = true;
    withNodeJs = true;
    withRuby = true;
    withPython3 = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
  };

  programs = {
    home-manager.enable = true;
    nix-index.enable = true;
    nix-index.enableFishIntegration = true;
    nix-index-database.comma.enable = true;

    starship.enable = true;
    starship.settings = {
      aws.disabled = true;
      gcloud.disabled = true;
      kubernetes.disabled = false;
      git_branch.style = "242";
      directory.style = "blue";
      directory.truncate_to_repo = false;
      directory.truncation_length = 8;
      python.disabled = true;
      ruby.disabled = true;
      hostname.ssh_only = false;
      hostname.style = "bold green";
    };

    fzf.enable = true;
    fzf.enableFishIntegration = true;
    lsd.enable = true;
    lsd.enableAliases = true;
    zoxide.enable = true;
    zoxide.enableFishIntegration = true;
    zoxide.options = ["--cmd cd"];
    broot.enable = true;
    broot.enableFishIntegration = true;
    direnv.enable = true;
    direnv.nix-direnv.enable = true;

    git = {
      enable = true;
      package = pkgs.unstable.git;
      delta.enable = true;
      delta.options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
      };
      userEmail = "andrzej.sliwa@gmail.com"; # FIXME: set your git email
      userName = "andrzejsliwa"; #FIXME: set your git username
      extraConfig = {
        credential = {
	        helper = "${pkgs.gh}/bin/gh auth git-credential";
	      };
	      include = {
	        path = "user";
	      };
        core = {
	        autocrlf = "input";
	      };
        alias = {
	        co = "checkout";
          st = "status";
          pushf = "push --force-with-lease";
          pullm = "pull origin main";
        };
        init = {
          defaultBranch = "main";
        };
        push = {
          default = "current";
          autoSetupRemote = true;
        };
	      pull = {
          rebase = "true";
	      };
	      fetch = {
          prune = "true";
        };
	      rebase = {
          autoSquash = "true";
          autoStash = "true";
        };
	      merge = {
          conflictStyle = "diff3";
        };
      };
    };

    atuin.enable = true;
    atuin.settings = {
      auto_sync = "true";
      style = "compact";
      sync_frequency = "10m";
      fuzzy_search_syntax = "fuzzy-match";
      inline_height = "10";
      show_preview = "true";
    };
    atuin.enableFishIntegration = true;

    fish = {
      enable = true;
      # run 'scoop install win32yank' on Windows, then add this line with your Windows username to the bottom of interactiveShellInit
      # fish_add_path --append /mnt/c/Users/<Your Windows Username>/scoop/apps/win32yank/0.1.1
      interactiveShellInit = ''
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

        ${pkgs.lib.strings.fileContents (pkgs.fetchFromGitHub {
            owner = "rebelot";
            repo = "kanagawa.nvim";
            rev = "de7fb5f5de25ab45ec6039e33c80aeecc891dd92";
            sha256 = "sha256-f/CUR0vhMJ1sZgztmVTPvmsAgp0kjFov843Mabdzvqo=";
          }
          + "/extras/kanagawa.fish")}
        # enable rbenv  
        status --is-interactive; and rbenv init - fish | source
        nh completions --shell fish | source
        # set -U fish_greeting
        fish_add_path --append /mnt/c/Users/Andrzej/scoop/apps/win32yank/0.1.1
     '';
      functions = {
        refresh = "source $HOME/.config/fish/config.fish";
        take = ''mkdir -p -- "$1" && cd -- "$1"'';
        ttake = "cd $(mktemp -d)";
        show_path = "echo $PATH | tr ' ' '\n'";
        posix-source = ''
          for i in (cat $argv)
            set arr (echo $i |tr = \n)
            set -gx $arr[1] $arr[2]
          end
        '';
      };
      shellAbbrs =
        {
          gc = "nix-collect-garbage --delete-old";
        }
        # navigation shortcuts
        // {
          ".." = "cd ..";
          "..." = "cd ../../";
          "...." = "cd ../../../";
          "....." = "cd ../../../../";
        }
        # git shortcuts
        // {
          gapa = "git add --patch";
          grpa = "git reset --patch";
          gst = "git status";
          gdh = "git diff HEAD";
          gp = "git push";
          gph = "git push -u origin HEAD";
          gco = "git checkout";
          gcob = "git checkout -b";
          gcm = "git checkout master";
          gcd = "git checkout develop";
          gsp = "git stash push -m";
          gsa = "git stash apply stash^{/";
          gsl = "git stash list";
        };
      shellAliases = {
        jvim = "nvim";
        lvim = "nvim";
        pbcopy = "/mnt/c/Windows/System32/clip.exe";
        pbpaste = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -command 'Get-Clipboard'";
        explorer = "/mnt/c/Windows/explorer.exe";
      };
      plugins = [
        {
          inherit (pkgs.fishPlugins.autopair) src;
          name = "autopair";
        }
        {
          inherit (pkgs.fishPlugins.done) src;
          name = "done";
        }
        {
          inherit (pkgs.fishPlugins.sponge) src;
          name = "sponge";
        }
      ];
    };
  };

   xdg.configFile.nvim.source = ./nvim;

  # home.file.".config/nvim" = {
  #  source = ./nvim;
  #  recursive = true;
  # };
}
