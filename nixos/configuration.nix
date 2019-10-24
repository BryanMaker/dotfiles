{ config, pkgs, lib, ... }:
let
  meta = import ./meta.nix;
  machine-config = lib.getAttr meta.name {
    omicron = [
      {
        imports = [
          <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
        ];
      
        boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];
      
        nix.maxJobs = lib.mkDefault 4;
      
        powerManagement.cpuFreqGovernor = "powersave";
      
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      }
      {
        boot.initrd.luks.devices = [
          {
            name = "root";
            device = "/dev/disk/by-uuid/8b591c68-48cb-49f0-b4b5-2cdf14d583dc";
            preLVM = true;
          }
        ];
        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/BA72-5382";
          fsType = "vfat";
        };
        fileSystems."/" = {
          device = "/dev/disk/by-uuid/434a4977-ea2c-44c0-b363-e7cf6e947f00";
          fsType = "ext4";
          options = [ "noatime" "nodiratime" "discard" ];
        };
        fileSystems."/home" = {
          device = "/dev/disk/by-uuid/8bfa73e5-c2f1-424e-9f5c-efb97090caf9";
          fsType = "ext4";
          options = [ "noatime" "nodiratime" "discard" ];
        };
        swapDevices = [
          { device = "/dev/disk/by-uuid/26a19f99-4f3a-4bd5-b2ed-359bed344b1e"; }
        ];
      }
      {
        services.xserver.libinput = {
          enable = true;
          accelSpeed = "0.7";
        };
      }
      {
        i18n = {
          consolePackages = [
            pkgs.terminus_font
          ];
          consoleFont = "ter-132n";
        };
      }
      {
        services.xserver.dpi = 276;
      }
    ];
  };

in
{
  imports = [
    {
      nixpkgs.config.allowUnfree = true;

      # The NixOS release to be compatible with for stateful data such as databases.
      system.stateVersion = "19.09";
    }

    {
      nix.nixPath =
        let dotfiles = "/home/rasen/dotfiles";
        in [
          "nixos-config=${dotfiles}/nixos/configuration.nix"
          "dotfiles=${dotfiles}"
          "${dotfiles}/channels"
        ];
    }
    {
      system.copySystemConfiguration = true;
    }
    {
      users.extraUsers.rasen = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "users" "wheel" "input" ];
        initialPassword = "HelloWorld";
      };
    }
    {
      nix.nixPath = [ "nixpkgs-overlays=/home/rasen/dotfiles/nixpkgs-overlays" ];
    }
    {
      nix.useSandbox = "relaxed";
    }
    {
      hardware.bluetooth.enable = true;
      hardware.pulseaudio = {
        enable = true;
    
        # NixOS allows either a lightweight build (default) or full build
        # of PulseAudio to be installed.  Only the full build has
        # Bluetooth support, so it must be selected here.
        package = pkgs.pulseaudioFull;
      };
    }
    {
      environment.systemPackages = [
        pkgs.ntfs3g
      ];
    }
    {
      networking = {
        hostName = meta.name;
    
        networkmanager.enable = true;
    
        # disable wpa_supplicant
        wireless.enable = false;
      };
    
      users.extraUsers.rasen.extraGroups = [ "networkmanager" ];
    
      environment.systemPackages = [
        pkgs.networkmanagerapplet
      ];
    }
    {
      hardware.pulseaudio = {
        enable = true;
        support32Bit = true;
      };
    
      environment.systemPackages = [ pkgs.pavucontrol ];
    }
    {
      services.locate = {
        enable = true;
        localuser = "rasen";
      };
    }
    {
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
      };
    }
    {
      programs.mosh.enable = true;
    }
    {
      services.gitolite = {
        enable = true;
        user = "git";
        adminPubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHH15uiQw3jBbrdlcRb8wOr8KVltuwbHP/JOFAzXFO1l/4QxnKs6Nno939ugULM7Lu0Vx5g6FreuCOa2NMWk5rcjIwOzjrZnHZ7aoAVnE7H9scuz8NGnrWdc1Oq0hmcDxdZrdKdB6CPG/diGWNZy77nLvz5JcX1kPLZENPeApCERwR5SvLecA4Es5JORHz9ssEcf8I7VFpAebfQYDu+VZZvEu03P2+5SXv8+5zjiuxM7qxzqRmv0U8eftii9xgVNC7FaoRBhhM7yKkpbnqX7IeSU3WeVcw4+d1d8b9wD/sFOyGc1xAcvafLaGdgeCQGU729DupRRJokpw6bBRQGH29 rasen@omicron";
      };
    }
    {
      services.dnsmasq = {
        enable = true;
    
        # These are used in addition to resolv.conf
        servers = [
          "8.8.8.8"
          "8.8.4.4"
        ];
    
        extraConfig = ''
          listen-address=127.0.0.1
          cache-size=1000
    
          no-negcache
        '';
      };
    }
    {
      services.syncthing = {
        enable = true;
        user = "rasen";
        dataDir = "/home/rasen/.config/syncthing";
        configDir = "/home/rasen/.config/syncthing";
        openDefaultPorts = true;
      };
    }
    {
      networking.firewall = {
        enable = true;
        allowPing = false;
    
        connectionTrackingModules = [];
        autoLoadConntrackHelpers = false;
      };
    }
    {
      virtualisation.docker.enable = true;
    }
    {
      environment.systemPackages = [ pkgs.borgbackup ];
    }
    {
      environment.systemPackages = [
        pkgs.isync
      ];
    }
    {
      services.dovecot2 = {
        enable = true;
        enablePop3 = false;
        enableImap = true;
        mailLocation = "maildir:~/Mail:LAYOUT=fs";
      };
    
      # dovecot has some helpers in libexec (namely, imap).
      environment.pathsToLink = [ "/libexec/dovecot" ];
    }
    {
      environment.systemPackages = [
        pkgs.msmtp
      ];
    }
    {
      environment.systemPackages = [
        pkgs.notmuch
      ];
    }
    {
      services.xserver.enable = true;
    }
    {
      i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    }
    {
      time.timeZone = "Europe/Kiev";
    }
    {
      services.xserver.displayManager.slim.enable = true;
    }
    {
      services.xserver.displayManager.slim.enable = true;
      services.xserver.windowManager = {
        default = "awesome";
        awesome = {
          enable = true;
          luaModules = [ pkgs.luaPackages.luafilesystem pkgs.luaPackages.cjson ];
        };
      };
    }
    {
      services.xserver.desktopManager.xterm.enable = false;
    }
    {
      environment.systemPackages = [
        pkgs.wmname
        pkgs.xclip
        pkgs.escrotum
      ];
    }
    {
      services.xserver.layout = "us,ua";
      services.xserver.xkbVariant = "workman,";
    
      # Use same config for linux console
      i18n.consoleUseXkbConfig = true;
    }
    {
      services.xserver.xkbOptions = "grp:lctrl_toggle,grp_led:caps,ctrl:nocaps";
    }
    {
      services.redshift = {
        enable = true;
      };
      location.provider = "geoclue2";
    }
    {
      hardware.acpilight.enable = true;
      environment.systemPackages = [
        pkgs.acpilight
      ];
      users.extraUsers.rasen.extraGroups = [ "video" ];
    }
    {
      fonts = {
        enableCoreFonts = true;
        enableFontDir = true;
        enableGhostscriptFonts = false;
    
        fonts = with pkgs; [
          inconsolata
          corefonts
          dejavu_fonts
          source-code-pro
          ubuntu_font_family
          unifont
        ];
      };
    }
    {
      environment.systemPackages = [
        pkgs.gnupg
        pkgs.pinentry
      ];
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    
      ## is it no longer needed?
      #
      # systemd.user.sockets.gpg-agent-ssh = {
      #   wantedBy = [ "sockets.target" ];
      #   listenStreams = [ "%t/gnupg/S.gpg-agent.ssh" ];
      #   socketConfig = {
      #     FileDescriptorName = "ssh";
      #     Service = "gpg-agent.service";
      #     SocketMode = "0600";
      #     DirectoryMode = "0700";
      #   };
      # };
    
      services.pcscd.enable = true;
    }
    {
      environment.systemPackages = [
        pkgs.yubikey-manager
        pkgs.yubikey-personalization
        pkgs.yubikey-personalization-gui
      ];
    
      services.udev.packages = [ pkgs.yubikey-personalization ];
    }
    {
      environment.systemPackages = [
        (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]))
      ];
    }
    {
      programs.browserpass.enable = true;
    }
    {
      environment.systemPackages = [
        pkgs.gwenview
        pkgs.dolphin
        pkgs.kdeFrameworks.kfilemetadata
        pkgs.filelight
        pkgs.shared_mime_info
      ];
    }
    {
      environment.pathsToLink = [ "/share" ];
    }
    {
      environment.systemPackages = [
        pkgs.google-chrome
      ];
    }
    {
      environment.systemPackages = [
        pkgs.firefox
        pkgs.icedtea_web
      ];
    }
    (let
      oldpkgs = import (pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs-channels";
        rev = "14cbeaa892da1d2f058d186b2d64d8b49e53a6fb";
        sha256 = "0lfhkf9vxx2l478mvbmwm70zj3vfn9365yax7kvm7yp07b5gclbr";
      }) { config = { firefox.icedtea = true; }; };
    in {
      nixpkgs.config.firefox = {
        icedtea = true;
      };
    
      environment.systemPackages = [
        (pkgs.runCommand "firefox-esr" { preferLocalBuild = true; } ''
          mkdir -p $out/bin
          ln -s ${oldpkgs.firefox-esr}/bin/firefox $out/bin/firefox-esr
        '')
      ];
    })
    {
      environment.systemPackages = [
        pkgs.zathura
      ];
    }
    {
      programs.slock.enable = true;
    }
    {
      environment.systemPackages = [
        pkgs.xss-lock
      ];
    }
    {
      environment.systemPackages = [
        pkgs.google-play-music-desktop-player
        pkgs.tdesktop # Telegram
    
        pkgs.mplayer
        pkgs.smplayer
    
        # Used by naga setup
        pkgs.xdotool
      ];
    }
    {
      environment.systemPackages = [
        (pkgs.vim_configurable.override { python3 = true; })
        pkgs.neovim
      ];
    }
    {
      services.emacs = {
        enable = true;
        defaultEditor = true;
        package = (pkgs.emacsPackagesNgGen pkgs.emacs).emacsWithPackages (epkgs:
          (with epkgs.melpaPackages; [
            use-package
            diminish
            el-patch
    
            evil
            evil-numbers
            evil-swap-keys
            evil-collection
            evil-surround
            evil-magit
            evil-org
    
            lispyville
            aggressive-indent
            paren-face
    
            smex
            ivy
            counsel
            counsel-projectile
            whitespace-cleanup-mode
            which-key
            projectile
            diff-hl
            yasnippet
            company
            flycheck
            color-identifiers-mode
            magit
            f
    
            imenu-list
            avy
            wgrep
            org-pomodoro
            org-cliplink
            org-download
            nix-mode
            haskell-mode
            rust-mode
            racer
            pip-requirements
            js2-mode
            rjsx-mode
            typescript-mode
            tide
            vue-mode
            web-mode
            groovy-mode
    
            lua-mode
    
            ledger-mode
            markdown-mode
            edit-indirect
            json-mode
            yaml-mode
            jinja2-mode
            gitconfig-mode
            terraform-mode
            graphviz-dot-mode
            fish-mode
            visual-fill-column
            beacon
            google-translate
            writegood-mode
            edit-server
    
            general
            flycheck-jest
            restclient
            mbsync
            nix-sandbox
            prettier-js
            flycheck-rust
            flycheck-inline
            monokai-theme
            spaceline
    
            lsp-mode
            lsp-ui
            company-lsp
    
            # provided by pkgs.notmuch:
            # notmuch
          ]) ++
          [
            epkgs.orgPackages.org-plus-contrib
    
            pkgs.ycmd
          ]
        );
      };
      environment.systemPackages = [
        pkgs.ripgrep
        (pkgs.aspellWithDicts (dicts: with dicts; [en en-computers en-science ru uk]))
    
        # pkgs.rustup
        # pkgs.rustracer
    
        # pkgs.clojure
        # pkgs.leiningen
      ];
      # environment.variables.RUST_SRC_PATH = "${pkgs.rustPlatform.rustcSrc}";
    }
    {
      environment.systemPackages = [
        pkgs.rxvt_unicode
      ];
    }
    {
      fonts = {
        fonts = [
          pkgs.powerline-fonts
          pkgs.terminus_font
        ];
      };
    }
    {
      programs.fish.enable = true;
      users.defaultUserShell = pkgs.fish;
    }
    {
      environment.systemPackages = [
        pkgs.gitFull
        pkgs.gitg
      ];
    }
    {
      environment.systemPackages = [
        pkgs.tmux
      ];
    }
    {
      environment.systemPackages = [
        pkgs.wget
        pkgs.htop
        pkgs.psmisc
        pkgs.zip
        pkgs.unzip
        pkgs.unrar
        pkgs.p7zip
        pkgs.bind
        pkgs.file
        pkgs.which
        pkgs.utillinuxCurses
    
        pkgs.patchelf
    
        pkgs.python
        pkgs.python3
    
        pkgs.awscli
        pkgs.nodejs-12_x # LTS
        pkgs.shellcheck
      ];
      environment.variables.NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      environment.variables.PATH = "$HOME/.npm-global/bin:$PATH";
    }
  ] ++ machine-config;
}
