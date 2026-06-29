{ config, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/github/dotfiles-mac-nix";
in
{
  home.username = "leebarry";
  home.homeDirectory = "/Users/leebarry";
  home.stateVersion = "23.11";
  home.language.base = "en_US.UTF-8";

  home.packages = with pkgs; [
    git
    gh                # GitHub CLI — gh-axi wraps it; brew's gh was zapped
    curl
    wget
    jq
    fd
    fastfetch
    ripgrep
    killall
    lazygit
    tree
    bun
    nodejs            # runtime for the AXI CLIs (gh-axi, lavish-axi, …); brew's node was zapped
    rustup
    zip
    unzip
    nerd-fonts.hack
    roboto
    noto-fonts
    noto-fonts-cjk-sans
    # noto-fonts-color-emoji dropped — pulls in afdko, whose test suite fails on
    # current nixpkgs-unstable (darwin). macOS already ships Apple Color Emoji.
    font-awesome
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Put user-installed CLIs on PATH. Home Manager replaced the dotfiles where these
  # lived, so restore them declaratively (sessionPath is sourced in .zshrc, so it also
  # reaches tmux panes):
  #   ~/.local/bin  -> Claude Code            (was in ~/.zshenv)
  #   /opt/homebrew -> brew shellenv: AXI CLIs, node, gh, …  (was in ~/.zprofile)
  home.sessionPath = [
    "$HOME/.local/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    signing.format = null;
    settings = {
      user = {
        name = "Korallis";
        email = "lee.barry84@gmail.com";
      };
      core.editor = "vim";
      color.ui = true;
      push.autoSetupRemote = true;
      pull.rebase = true;
      rebase.updateRefs = true;

      # authenticate `git push` to GitHub via the gh CLI (on PATH via Nix) —
      # no token stored in the repo, no interactive prompt
      credential."https://github.com".helper = "!gh auth git-credential";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      command_timeout = 1000;
      add_newline = false;
      format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration$line_break$character";

      directory.style = "blue";

      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };

      git_branch = {
        format = "[$branch]($style)";
        style = "bright-black";
      };

      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
        style = "cyan";
        stashed = "≡";
      };

      git_state = {
        format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
        style = "bright-black";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };

      python = {
        format = "[$virtualenv]($style) ";
        style = "bright-black";
      };
    };
  };

  programs.tmux = {
    enable = true;
    prefix = "C-Space";          # ergonomic prefix; leaves C-a / C-e free in the shell
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;               # windows start at 1, not 0
    escapeTime = 0;              # no <Esc> delay (vim-friendly)
    historyLimit = 50000;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      {
        plugin = resurrect;      # save/restore sessions (prefix C-s / C-r)
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = continuum;      # auto-save every 10 min, auto-restore on launch
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
    extraConfig = ''
      # truecolor passthrough (matches WezTerm)
      set -ga terminal-overrides ",*256col*:Tc"
      set -g focus-events on
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g status-interval 5

      # reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "tmux.conf reloaded"

      # splits / new window keep the current directory
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # repeatable pane resize (hold Ctrl-Space)
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # cycle windows
      bind -r C-h previous-window
      bind -r C-l next-window

      # vi copy-mode -> macOS clipboard
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"

      # ---- Rose Pine (moon) status line, to match wezterm.lua ----
      set -g status-style "bg=default,fg=#e0def4"
      set -g status-left "#[fg=#c4a7e7,bold] #S #[default]"
      set -g status-left-length 30
      set -g status-right "#[fg=#9ccfd8] %H:%M #[fg=#6e6a86] %d %b "
      set -g window-status-format "#[fg=#6e6a86] #I:#W "
      set -g window-status-current-format "#[fg=#232136,bg=#c4a7e7,bold] #I:#W "
      set -g pane-border-style "fg=#393552"
      set -g pane-active-border-style "fg=#c4a7e7"
      set -g message-style "bg=#2a273f,fg=#e0def4"
      set -g mode-style "bg=#393552,fg=#e0def4"
    '';
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ".." = "cd ..";

      # launch Claude Code: bypass permission prompts + Chrome integration
      cc = "claude --dangerously-skip-permissions --chrome";
      m = "git switch main";
      mst = "git switch master";
      pull = "git pull";
      push = "git push";
      pushf = "git push --force";
      add = "git add .";
      amend = "git commit --amend";
      reset = "git reset --soft HEAD^";
      rebasem = "git rebase -i main";
      rebasemst = "git rebase -i master";
      rebuild = "/run/current-system/sw/bin/darwin-rebuild switch --flake ~/github/dotfiles-mac-nix#mac";
    };
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
  };

  home.file = {
    ".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/files/.config/wezterm";
  };
}
