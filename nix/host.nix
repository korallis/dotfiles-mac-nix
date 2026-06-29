{ pkgs, ... }:

{
  # If you use Determinate Nix Installer (recommended), let it manage Nix itself.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  homebrew = {
    enable = true;
    # "none": don't auto-uninstall Homebrew pkgs that aren't declared below — otherwise
    # manually-installed workflow tools (gh-axi, etc.) get wiped on every rebuild.
    # Upstream used "zap"; switch back once every brew pkg is declared here.
    onActivation.cleanup = "none";
    taps = [ ];
    brews = [
      "autoconf"
    ];
    casks = [
      "wezterm"
      "amethyst"
      "opensuperwhisper"   # local Whisper push-to-talk dictation (menu-bar app)
    ];
  };

  environment.systemPackages = with pkgs; [
    starship
  ];

  system.primaryUser = "leebarry";
  users.users.leebarry = {
    home = "/Users/leebarry";
    shell = pkgs.zsh;
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.swipescrolldirection" = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      AppleShowAllExtensions = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
    };

    trackpad = {
      Clicking = true;
    };
  };

  environment.systemPath = [
    "/run/current-system/sw/bin"
    "/etc/profiles/per-user/leebarry/bin"
    # System-level PATH (set by nix-darwin's /etc shell init, before any Home Manager
    # hook or session-var guard) so even a stale tmux server's new panes find the
    # firstmate toolchain. NB: a process already running keeps its old PATH, so an
    # existing tmux server still has to be restarted once for this to take effect.
    "/opt/homebrew/bin"            # AXI CLIs: gh-axi, chrome-devtools-axi, lavish-axi
    "/opt/homebrew/sbin"
    "/Users/leebarry/.local/bin"   # claude, treehouse, no-mistakes
  ];

  system.stateVersion = 6;
}
