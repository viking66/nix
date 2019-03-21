{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  home.keyboard.layout = "dvorak";

  xdg.enable = true;

  programs.home-manager = {
    enable = true;
    path = "https://github.com/rycee/home-manager/archive/release-18.09.tar.gz";
  };

  home.packages = with pkgs; [
    chromium
    dmenu
    direnv
    feh
    gnupg
    ipfs
    pass
    pavucontrol
    pinentry_ncurses
    signal-desktop
    tmux
    xclip
    zathura
  ];

  xsession = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      extraPackages = haskellPackages: [
        haskellPackages.xmonad-contrib
        haskellPackages.xmonad-extras
        haskellPackages.xmonad
      ];
      config = pkgs.writeText "xmonad.hs" ''
        import XMonad
        import XMonad.Actions.Volume
        import XMonad.Hooks.EwmhDesktops
        import XMonad.Hooks.ManageDocks
        import XMonad.Layout.NoBorders
        import XMonad.Util.EZConfig

        myManageHook = manageDocks <+> composeAll
          [ className =? "mpv" --> doFloat ]

        myKeyBindings =
          [ ("<XF86AudioMute>", spawn $ "amixer set Master toggle")
          , ("<XF86AudioLowerVolume>", spawn $ "amixer -q set Master 3%-")
          , ("<XF86AudioRaiseVolume>", spawn $ "amixer -q set Master 3%+")
          , ("<XF86AudioMicMute>", spawn $ "amixer set Capture toggle")
          , ("<XF86MonBrightnessDown>", spawn $ "xbacklight -dec 5")
          , ("<XF86MonBrightnessUp>", spawn $ "xbacklight -inc 5")
          ]

        myConfig = defaultConfig
          { terminal = "termite"
          , layoutHook = avoidStruts $ smartBorders $ layoutHook defaultConfig
          , manageHook = myManageHook
          , handleEventHook = fullscreenEventHook
          }
          `additionalKeysP` myKeyBindings

        main = do
          xmonad $ docks $ myConfig
      '';
    };
    profileExtra = ''
      feh --bg-scale ~/.backgrounds/ocean.jpg &
      xinput set-prop "TPPS/2 Elan TrackPoint" "Evdev Wheel Emulation" 1
      xinput set-prop "TPPS/2 Elan TrackPoint" "Evdev Wheel Emulation Button" 2
      xinput set-prop "TPPS/2 Elan TrackPoint" "Evdev Wheel Emulation Timeout" 200
      xinput set-prop "TPPS/2 Elan TrackPoint" "Evdev Wheel Emulation Axes" 6 7 4 5
      xinput set-prop "TPPS/2 Elan TrackPoint" "Device Accel Constant Deceleration" .5
    '';
  };

  programs.bash = {
    enable = true;
    historyControl = [
      "erasedups"
      "ignoredups"
      "ignorespace"
    ];
    historyFileSize = -1;
    historySize = -1;
    sessionVariables = {
      GREP_COLOR = "1;33";
      LESS = "-R";
      EDITOR = "nvim";
    };
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -l --color=auto";
      grep = "grep --color=auto";
      v = "nvim";
      tmux = "tmux -2";
      homix = "nix-env -i --remove-all homix";
    };
    initExtra = ''
      set -o vi
      complete -cf sudo
      test -z "$TMUX" && exec tmux

      haskell-shell() {
        nix-shell -p "haskellPackages.ghcWithPackages (pkgs: with pkgs; [$@])"
      }

      hs-envrc() {
        declare -a pkgs=("brittany" "ghcid" "hlint" "cabal-install" "hasktags" "haskdogs")
        echo "use nix" > .envrc
        for pkg in "''${pkgs[@]}"; do
          echo "use nix -p haskellPackages.''${pkg}" >> .envrc
        done
      }

      default-nix() {
        echo "{ pkgs ? import <nixpkgs> {} }:" > default.nix
        echo "pkgs.haskellPackages.developPackage { root = ./.; }" >> default.nix
      }

      prompt_command () {
          local rts=$?
          local w=$(echo "''${PWD/#$HOME/~}" | sed 's/.*\/\(.*\/.*\/.*\)$/\1/') # pwd max depth 3
      # pwd max length L, prefix shortened pwd with m
          local L=30 m='...'
          [ ''${#w} -gt $L ] && { local n=$((''${#w} - $L + ''${#m}))
          local w="\[\033[0;32m\]''${m}\[\033[0;37m\]''${w:$n}\[\033[0m\]" ; } \
          ||   local w="\[\033[0;37m\]''${w}\[\033[0m\]"
      # different colors for different return status
          [ $rts -eq 0 ] && \
          local p="\[\033[0;36m\]>\[\033[1;36m\]>\[\033[m\]" || \
          local p="\[\033[0;31m\]>\[\033[1;31m\]>\[\033[m\]"
          PS1="''${w} ''${p} "
          history -a; history -c; history -r
      }
      PROMPT_COMMAND=prompt_command
      eval "$(direnv hook bash)"
    '';
  };

  programs.command-not-found.enable = true;

  programs.git = {
    enable = true;
    userName = "Jason Davidson";
    userEmail = "jad658@gmail.com";
    aliases = {
      d = "difftool";
      m = "merge --ff-only";
      st = "status -sb";
      ci = "commit";
      br = "branch";
      co = "checkout";
      com = "\"!f() { git checkout -b $1 -t origin/mainline; }; f\"";
      save = "\"!f() { git stash save $1$(date +'(%Y.%m.%d %H:%M)'); }; f\"";
      sync = "pull --rebase";
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
      lgg = "log --color --graph --pretty=format:'%Cred%H%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --no-abbrev-commit --";
      dag = "log --graph --format='format:%C(yellow)%h%C(reset) %C(blue)\\\"%an\\\" <%ae>%C(reset) %C(magenta)%cr%C(reset)%C(auto)%d%C(reset)%n%s' --date-order";
    };
    extraConfig = ''
      [core]
          editor = nvim
          trustctime = false
          page = less -FMRiX
      [diff]
          tool = vimdiff
      [difftool]
          prompt = false
      [difftool "vimdiff"]
          cmd = nvim -d $LOCAL $REMOTE
      [merge]
          tool = vimdiff
      [mergetool "vimdiff"]
          cmd = nvim -d $BASE $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'
      [color]
          ui = true
          diff = auto
          status = auto
          branch = auto
      [credential]
          helper = cache
    '';
  };

  programs.neovim = {
    enable = true;
    configure = {
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          supertab
          vim-airline
          vim-airline-themes
          vim-colors-solarized
          vim-commentary
          # TODO push change to add the following plugin
          # indentLine
        ];
      };
      customRC = ''
        "" Make vim less annoying
        set nocompatible
        filetype plugin indent on
        set autoread
        set lazyredraw
        set noerrorbells
        set timeout timeoutlen=1000 ttimeoutlen=100

        "" Add some color
        syntax on
        set background=dark
        colorscheme solarized
        set termguicolors
        set showmatch
        set synmaxcol=120

        "" TODO - configure backup and tmp files

        "" Use spaces instead of tabs
        set expandtab
        set smarttab
        set tabstop=2
        set shiftwidth=2
        set softtabstop=2
        set autoindent
        set backspace=indent,eol,start

        "" Highlight trailing whitespace
        highlight ExtraWhitespace ctermbg=red guibg=red
        au ColorScheme * highlight ExtraWhitespace guibg=red
        au BufEnter * match ExtraWhitespace /\s\+$\|\t/
        au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
        au InsertLeave * match ExtraWhiteSpace /\s\+$/

        "" Configure title and status bar
        set laststatus=2
        set report=0
        set showcmd

        "" Enable line numbers
        set number
        set numberwidth=5

        "" Scrolling behavior
        set scrolloff=10
        set sidescrolloff=10

        "" Better tab completion
        set wildmenu
        set wildmode=list:longest
        set ofu=syntaxcomplete#Complete
        set completeopt+=longest
        set complete+=k
        au Filetype text setlocal dictionary+=/usr/share/dict/words

        "" Supertab settings
        let g:SuperTabDefaultCompletionType = "context"
        let g:SuperTabLongestEnhanced = 1
        let g:SuperTabLongestHighlight = 1

        "" Better search behavior
        set incsearch
        set ignorecase
        set smartcase
        set infercase

        "" Search for selected text, forwards or backwards.
        vnoremap <silent> * :<C-U>
          \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
          \gvy/<C-R><C-R>=substitute(
          \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
          \gV:call setreg('"', old_reg, old_regtype)<CR>
        vnoremap <silent> # :<C-U>
          \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
          \gvy?<C-R><C-R>=substitute(
          \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
          \gV:call setreg('"', old_reg, old_regtype)<CR>

        "" Ignore whitespace and case in vimdiff
        set diffopt+=iwhite
        set diffopt+=icase

        "" Automatically leave insert mode after 15 seconds of inactivity
        au CursorHoldI * stopinsert
        au InsertEnter * let updaterestore=&updatetime | set updatetime=15000
        au InsertLeave * let &updatetime=updaterestore

        "" Set leader to ,
        let mapleader = ","
        let g:mapleader = ","

        "" Mappings
        "" t => down
        "" T => join lines
        "" n => up
        "" N => help
        "" s => right
        "" S => screen bottom
        "" j => jump(til)
        "" J => jump(til) previous
        "" k => klobber(subst) char
        "" K => klobber(subst) line
        "" l => leap(next)
        "" L => leap(previous)
        "" - => beg line
        "" _ => end line
        no t j
        no T J
        no n k
        no N K
        no s l
        no S L
        no j t
        no J T
        no k s
        no K S
        no l n
        no L N
        no - ^
        no _ $

        map ; :
        inoremap jj <Esc>
        nmap <leader>s :set spell!<CR>
        nmap <leader>p :set paste!<CR>
        nmap <leader>h :set hlsearch!<CR>
        nmap <leader>n :exec &nu ? "set rnu" : "set nu"<CR>
        nmap <leader>c :exec &cc=="" ? "set cc=80" : "set cc="<CR>
        nmap <leader>x :exec &cuc && &cul ? "set nocuc nocul" : "set cuc cul"<CR>
        nmap <leader>w :%s/\s\+$//g<CR>
        nmap <leader>b :%!brittany 2> /dev/null<CR>

        let g:airline_powerline_fonts=1

        "" Visualize tabs
        let g:indentLine_char = '│'
      '';
    };
  };

  programs.termite = {
    enable = true;
    font = "Inconsolata-dz for Powerline 9";
    clickableUrl = true;
    colorsExtra = ''
      foreground = #93a1a1
      foreground_bold = #eee8d5
      cursor = #eee8d5
      cursor_foreground = #002b36
      background = #002B36
      color0 = #002b36
      color8 = #657b83
      color7 = #93a1a1
      color15 = #fdf6e3
      color1 = #dc322f
      color9 = #dc322f
      color2 = #859900
      color10 = #859900
      color3 = #b58900
      color11 = #b58900
      color4 = #268bd2
      color12 = #268bd2
      color5 = #6c71c4
      color13 = #6c71c4
      color6 = #2aa198
      color14 = #2aa198
      color16 = #cb4b16
      color17 = #d33682
      color18 = #073642
      color19 = #586e75
      color20 = #839496
      color21 = #eee8d5
    '';
  };

  home.file.".tmux.conf".text = ''
    # cat << "EOF" > /dev/null

    # Enable 256 colors
    set -g default-terminal "screen-256color"

    # Enable 24-bit color
    # set -ga terminal-overrides ",xterm-termite:Tc"

    # Use ` instead of ctrl-b
    unbind C-b
    set -g prefix `
    bind ` send-prefix

    # Set scrollback to 10000 lines
    set -g history-limit 10000

    # status bar on top
    set-option -g status-position top

    # Start index at 1
    set -g base-index 1

    # Renumber windows when window closes
    set -g renumber-windows on

    # set window title to user@server
    set -g set-titles on
    set -g set-titles-string '#h ❐ #S ● #I #W'

    # Splits
    bind a split-window -h
    bind A split-window -v

    # listen to alerts from all windows
    set -g bell-action any

    # enable mouse scroll
    set -g mouse on

    set -sg escape-time 0

    # clipboard copy/paste
    set-window-option -g mode-keys vi
    unbind c
    bind c copy-mode
    unbind p
    bind p paste-buffer
    bind -T copy-mode-vi 'v' send -X begin-selection
    bind -T copy-mode-vi 'V' send -X select-line
    bind -T copy-mode-vi 'r' send -X rectangle-toggle
    bind -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "xclip -in -selection clipboard && xclip -out -selection clipboard | xclip -in -selection primary"
    bind -T copy-mode-vi 't' send -X cursor-down
    bind -T copy-mode-vi 'n' send -X cursor-up
    bind -T copy-mode-vi 'h' send -X cursor-left
    bind -T copy-mode-vi 's' send -X cursor-right

    # monitor activity
    setw -g monitor-activity on
    set -g visual-activity on

    # When leaving a mode we reload this config, restoring default bindings
    unbind -n h
    unbind -n t
    unbind -n n
    unbind -n s
    unbind -n H
    unbind -n T
    unbind -n N
    unbind -n S
    unbind -n enter

    # Enter pane mode (aka split mode)
    bind s \
        bind -n h select-pane -L \; \
        bind -n t select-pane -D \; \
        bind -n n select-pane -U \; \
        bind -n s select-pane -R \; \
        bind -n H resize-pane -L 5 \; \
        bind -n T resize-pane -D 5 \; \
        bind -n N resize-pane -U 5 \; \
        bind -n S resize-pane -R 5 \; \
        bind -n enter source-file ~/.tmux.conf \; \
        run 'cut -c3- ~/.tmux.conf | sh -s status_right "SPLIT"'

    # Enter window mode (aka tab mode)
    bind t \
        bind -n t new-window \; \
        bind -n n command-prompt 'rename-window %%' \; \
        bind -n h prev \; \
        bind -n s next \; \
        bind -n H swap-window -t -1 \; \
        bind -n S swap-window -t +1 \; \
        bind -n enter source-file ~/.tmux.conf \; \
        run 'cut -c3- ~/.tmux.conf | sh -s status_right "TAB"'

    # -- 8< ------------------------------------------------------------------------

    run 'cut -c3- ~/.tmux.conf | sh -s apply_theme'

    # EOF
    #
    # # exit the script if any statement returns a non-true return value
    # set -e
    #
    # apply_theme() {
    #   left_separator=''
    #   left_separator_black=''
    #
    #   # panes
    #   tmux_conf_theme_pane_border_fg=''${tmux_conf_theme_pane_border_fg:-colour238}               # light gray
    #   tmux_conf_theme_pane_active_border_fg=''${tmux_conf_theme_pane_active_border_fg:-colour39}  # light blue
    #
    #   tmux set -g pane-border-style fg=$tmux_conf_theme_pane_border_fg \; set -g pane-active-border-style fg=$tmux_conf_theme_pane_active_border_fg
    #
    #   tmux_conf_theme_display_panes_active_colour=''${tmux_conf_theme_display_panes_active_colour:-colour39}  # light blue
    #   tmux_conf_theme_display_panes_colour=''${tmux_conf_theme_display_panes_colour:-colour39}                # light blue
    #   tmux set -g display-panes-active-colour $tmux_conf_theme_display_panes_active_colour \; set -g display-panes-colour $tmux_conf_theme_display_panes_colour
    #
    #   # messages
    #   tmux_conf_theme_message_fg=''${tmux_conf_theme_message_fg:-colour16}  # black
    #   tmux_conf_theme_message_bg=''${tmux_conf_theme_message_bg:-colour238} # light gray
    #   tmux_conf_theme_message_attr=''${tmux_conf_theme_message_attr:-bold}
    #   tmux set -g message-style fg=$tmux_conf_theme_message_fg,bg=$tmux_conf_theme_message_bg,$tmux_conf_theme_message_attr
    #
    #   tmux_conf_theme_message_command_fg=''${tmux_conf_theme_message_command_fg:-colour16}   # black
    #   tmux_conf_theme_message_command_bg=''${tmux_conf_theme_message_command_bg:-colour238}  # light gray
    #   tmux set -g message-command-style fg=$tmux_conf_theme_message_command_fg,bg=$tmux_conf_theme_message_command_bg,$tmux_conf_theme_message_attr
    #
    #   # windows mode
    #   tmux_conf_theme_mode_fg=''${tmux_conf_theme_mode_fg:-colour16}  # black
    #   tmux_conf_theme_mode_bg=''${tmux_conf_theme_mode_bg:-colour238} # light gray
    #   tmux_conf_theme_mode_attr=''${tmux_conf_theme_mode_attr:-bold}
    #   tmux setw -g mode-style fg=$tmux_conf_theme_mode_fg,bg=$tmux_conf_theme_mode_bg,$tmux_conf_theme_mode_attr
    #
    #   # status line
    #   tmux_conf_theme_status_fg=''${tmux_conf_theme_status_fg:-colour253} # white
    #   tmux_conf_theme_status_bg=''${tmux_conf_theme_status_bg:-colour232} # dark gray
    #   tmux set -g status-style fg=$tmux_conf_theme_status_fg,bg=$tmux_conf_theme_status_bg
    #
    #   tmux_conf_theme_session_fg=''${tmux_conf_theme_session_fg:-colour16}  # black
    #   tmux_conf_theme_session_bg=''${tmux_conf_theme_session_bg:-colour238} # light gray
    #   status_left="#[fg=$tmux_conf_theme_session_fg,bg=$tmux_conf_theme_session_bg,bold] ❐ #S #[fg=$tmux_conf_theme_session_bg,bg=$tmux_conf_theme_status_bg,nobold]$left_separator_black"
    #   if [ x"`tmux -q -L tmux_theme_status_left_test -f /dev/null new-session -d \; show -g -v status-left \; kill-session`" = x"[#S] " ] ; then
    #     status_left="$status_left "
    #   fi
    #   tmux set -g status-left-length 32 \; set -g status-left "$status_left"
    #
    #   tmux_conf_theme_window_status_fg=''${tmux_conf_theme_window_status_fg:-colour245} # light gray
    #   tmux_conf_theme_window_status_bg=''${tmux_conf_theme_window_status_bg:-colour232} # dark gray
    #   window_status_format="#I #W"
    #   tmux setw -g window-status-style fg=$tmux_conf_theme_window_status_fg,bg=$tmux_conf_theme_window_status_bg \; setw -g window-status-format "$window_status_format"
    #
    #   tmux_conf_theme_window_status_current_fg=''${tmux_conf_theme_window_status_current_fg:-colour16} # black
    #   tmux_conf_theme_window_status_current_bg=''${tmux_conf_theme_window_status_current_bg:-colour39} # light blue
    #   window_status_current_format="#[fg=$tmux_conf_theme_window_status_bg,bg=$tmux_conf_theme_window_status_current_bg]$left_separator_black#[fg=$tmux_conf_theme_window_status_current_fg,bg=$tmux_conf_theme_window_status_current_bg,bold] #I $left_separator #W #[fg=$tmux_conf_theme_window_status_current_bg,bg=$tmux_conf_theme_status_bg,nobold]$left_separator_black"
    #   tmux setw -g window-status-current-format "$window_status_current_format"
    #   tmux set -g status-justify left
    #
    #   tmux_conf_theme_window_status_activity_fg=''${tmux_conf_theme_window_status_activity_fg:-default}
    #   tmux_conf_theme_window_status_activity_bg=''${tmux_conf_theme_window_status_activity_bg:-default}
    #   tmux_conf_theme_window_status_activity_attr=''${tmux_conf_theme_window_status_activity_attr:-underscore}
    #   tmux setw -g window-status-activity-style fg=$tmux_conf_theme_window_status_activity_fg,bg=$tmux_conf_theme_window_status_activity_bg,$tmux_conf_theme_window_status_activity_attr
    #
    #   tmux_conf_theme_window_status_bell_fg=''${tmux_conf_theme_window_status_bell_fg:-colour238} # light gray
    #   tmux_conf_theme_window_status_bell_bg=''${tmux_conf_theme_window_status_bell_bg:-default}
    #   tmux_conf_theme_window_status_bell_attr=''${tmux_conf_theme_window_status_bell_attr:-blink,bold}
    #   tmux setw -g window-status-bell-style fg=$tmux_conf_theme_window_status_bell_fg,bg=$tmux_conf_theme_window_status_bell_bg,$tmux_conf_theme_window_status_bell_attr
    #
    #   window_status_last_fg=colour39 # light blue
    #   window_status_last_attr=default
    #   tmux setw -g window-status-last-style $window_status_last_attr,fg=$window_status_last_fg
    #
    #   $(cut -c3- ~/.tmux.conf | sh -s status_right)
    #
    #   # clock
    #   clock_mode_colour=colour39  # light blue
    #   tmux setw -g clock-mode-colour $clock_mode_colour
    # }
    #
    # status_right() {
    #   right_separator_black=''
    #   right_separator=''
    #   tmux_conf_theme_time_fg=''${tmux_conf_theme_time_date_fg:-colour39}       # light blue
    #   tmux_conf_theme_date_fg=''${tmux_conf_theme_time_date_fg:-colour247}      # light gray
    #   tmux_conf_theme_mode_bg=colour160                                       # red
    #   tmux_conf_theme_hostname_fg=colour16                                    # black
    #   tmux_conf_theme_hostname_bg=colour238                                   # light gray
    #
    #   status_right_time="#[fg=$tmux_conf_theme_time_fg,nobold]%R "
    #   status_right_date="#[fg=$tmux_conf_theme_date_fg,nobold]%F "
    #
    #   if [ x"$1" = x"" ] ; then
    #       status_right_mode=""
    #       status_right_hostname="#[fg=$tmux_conf_theme_hostname_bg,nobold]$right_separator_black#[fg=$tmux_conf_theme_hostname_fg,bg=$tmux_conf_theme_hostname_bg,bold] #h "
    #   else
    #       status_right_mode="#[fg=$tmux_conf_theme_mode_bg,nobold]$right_separator_black#[fg=$tmux_conf_theme_hostname_fg,bg=$tmux_conf_theme_mode_bg,bold] $1 "
    #       status_right_hostname="#[fg=$tmux_conf_theme_hostname_fg,bg=$tmux_conf_theme_mode_bg,bold] $right_separator #h "
    #   fi
    #
    #   status_right="''${status_right_prefix}''${status_right_time}''${status_right_date}''${status_right_mode}''${status_right_hostname}"
    #   tmux set -g status-right-length 64 \; set -g status-right "$status_right"
    # }
    #
    # $@
  '';

  services.gpg-agent = {
    enable = true;
    extraConfig = ''
      pinentry-program /home/jason/.nix-profile/bin/pinentry-curses
    '';
  };

  home.file.".asoundrc".text = ''
    pcm.!default {
        type hw
        slave.pcm "softvol"
    }

    pcm.softvol {
        type softvol
        slave.pcm "dmix"
        control { name "Pre-Amp"; card 0; }
        max_dB 32.0
    }
  '';
}
