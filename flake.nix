{
  description = "Mehdi Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager}: 
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      
      nixpkgs.config.allowUnfree = true;

      system.keyboard.enableKeyMapping = true;
      system.keyboard.remapCapsLockToControl = true;

      
      environment.systemPackages =
        [ 
          pkgs.git
          pkgs.gh
          pkgs.fd
          pkgs.mkalias
          pkgs.ripgrep
          pkgs.bat
          pkgs.fzf
          pkgs.zoxide
          pkgs.lazygit
          pkgs.eza
          pkgs.aerospace
          pkgs.starship
          pkgs.hidden-bar
        ];

      # Set up homebrew.
      homebrew = {
        # Add Nix to the PATH via Homebrew.
        enable = true;
        # Mas apps to install.
        masApps = {
          "Outlook" = 985367838;
        };

        # Homebrew taps to install.
        taps = [
          "FelixKratz/formulae"
        ];
        # Homebrew packages to install.
        brews = [
          "neovim"
          "tmux"
          "mas"
          "zsh-syntax-highlighting"
          "zsh-autosuggestions"
          "zsh-completions"
          "borders"
          "go"
        ];

        # Homebrew casksto install.
        casks = [
         "the-unarchiver"
         "1password"
         "orbstack"
         "miniconda"
         "wezterm"
         "arc"
         "zen-browser"
         "tableplus"
         "alacritty"
         "raycast"
         "kitty"
         "cleanshot"
         ];

         onActivation.cleanup = "zap";
         onActivation.autoUpdate = true;
         onActivation.upgrade = true;
                  

      };

      # Set fonts
      fonts.packages = [
        (pkgs.nerdfonts.override {fonts = [ "JetBrainsMono" ];})
      ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      # System configuration
      system.defaults = {
          # Dock Settings
          dock.autohide = true;
          dock.autohide-time-modifier = 0.0;
          dock.autohide-delay = 0.0;
          dock.tilesize = 50;
          dock.persistent-apps = [
              "/System/Applications/System Settings.app"
              "/System/Volumes/Data/Applications/Microsoft Outlook.app"
              "/Applications/Arc.app"
              "/Applications/WezTerm.app"
              "/Applications/TablePlus.app"
              
          ];
          dock.persistent-others = [
              "/Users/mehdimerkachi/Downloads"
              "/Applications"
          ];
          dock.show-recents = false;

          # Finder Settings
          finder.FXPreferredViewStyle = "clmv";
          finder._FXShowPosixPathInTitle = true;
          finder.ShowPathbar = true;
          finder.ShowStatusBar = true;

          # Login Window Settings
          loginwindow.GuestEnabled = false;              # Disable guest account login

          # Global Settings
          NSGlobalDomain."com.apple.mouse.tapBehavior" = 1; # Enable tap to click with mouse
          NSGlobalDomain.AppleInterfaceStyle = "Dark";   # Set the interface style to Dark mode
          NSGlobalDomain.KeyRepeat = 2;                   # Set key repeat rate

      };

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      users.users.mehdimerkachi = {
          name = "mehdimerkachi";
          home = "/Users/mehdimerkachi";
      };

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
    homeconfig = { config, pkgs, ...}: {
      # this is internal compatibility configuration 
      # for home-manager, don't change this!
      home.stateVersion = "23.05";
      # Let home-manager install and manage itself.
      programs.home-manager.enable = true;

      home.packages = with pkgs; [];

      home.sessionVariables = {
          EDITOR = "neovim";
      };
      
      targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;

      home.file = {
      "/Users/mehdimerkachi/.config/nvim".source = config.lib.file.mkOutOfStoreSymlink "/Users/mehdimerkachi/dotfiles/nvim";
      "/Users/mehdimerkachi/.config/tmux".source = config.lib.file.mkOutOfStoreSymlink  "/Users/mehdimerkachi/dotfiles/tmux";
      "/Users/mehdimerkachi/.config/aerospace".source = config.lib.file.mkOutOfStoreSymlink  "/Users/mehdimerkachi/dotfiles/aerospace";
      "/Users/mehdimerkachi/.config/alacritty".source = config.lib.file.mkOutOfStoreSymlink  "/Users/mehdimerkachi/dotfiles/alacritty";
      "/Users/mehdimerkachi/.config/wezterm".source = config.lib.file.mkOutOfStoreSymlink  "/Users/mehdimerkachi/dotfiles/wezterm";
      "/Users/mehdimerkachi/.config/starship".source = config.lib.file.mkOutOfStoreSymlink  "/Users/mehdimerkachi/dotfiles/starship";
      "/Users/mehdimerkachi/.zshrc".source = config.lib.file.mkOutOfStoreSymlink  "/Users/mehdimerkachi/dotfiles/.zshrc";
      };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Mehdis-MacBook-Air
    darwinConfigurations."Mehdis-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ 
      configuration
      nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "mehdimerkachi";

          };
        }
        home-manager.darwinModules.home-manager  {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.verbose = true;
                home-manager.users.mehdimerkachi = homeconfig;
            }

      ];

    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Mehdis-MacBook-Air".pkgs;
  };
}

