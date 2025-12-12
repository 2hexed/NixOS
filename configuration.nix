{ config, lib, pkgs, ... }:

let
  userPasswdFile = "/etc/nixos/user-password";

  passwordConfiguration = if builtins.pathExists userPasswdFile then {
    hashedPasswordFile = userPasswdFile;
  } else {
    initialPassword = "";
  };

in {
  imports = [
    ./hardware-configuration.nix
    /home/nick/Documents/chromium.nix
    /home/nick/Documents/brave.nix
  ];

  zramSwap.enable = true;
  time.timeZone = "Asia/Kolkata";

  fonts = {
    packages = (with pkgs; [ ]) ++ (with pkgs.nerd-fonts; [ symbols-only ]);
  };

  qt = {
    enable = true;
    style = "breeze";
    platformTheme = "gnome";
  };

  security.sudo.extraRules = [{
    groups = [ "wheel" ];
    commands = [{
      options = [ "NOPASSWD" ];
      command =
        "/run/current-system/sw/bin/tee /sys/bus/platform/drivers/ideapad_acpi/VPC????\\:??/conservation_mode";
    }];
  }];

  boot = {
    plymouth.enable = true;
    tmp.cleanOnBoot = true;
    kernelModules = [ "v4l2loopback" ];
    kernelParams = [ "quiet" "splash" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';

    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "snowflake";
    firewall.allowedTCPPorts = [ ];
    firewall.allowedUDPPorts = [ ];

    networkmanager = {
      enable = true;
      # wifi.macAddress = "random";
      ethernet.macAddress = "random";
      insertNameservers =
        [ "1.1.1.2" "1.0.0.2" "2606:4700:4700::1112" "2606:4700:4700::1002" ];
    };
  };

  hardware = {
    graphics.enable = true;
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.beta;

      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
        sync.enable = true;
      };
    };
  };

  services = {
    fstrim.enable = true;
    switcherooControl.enable = true;
    system76-scheduler.enable = true;
    desktopManager.cosmic.enable = true;
    displayManager.cosmic-greeter.enable = true;

    jellyfin = {
      enable = true;
      openFirewall = true;
      dataDir = "/home/jellyfin";
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
  };

  users.users.nick = {
    isNormalUser = true;
    description = "Nick";
    extraGroups = [ "audio" "video" "wheel" "networkmanager" ];
    packages = with pkgs; [
      delfin
      smassh
      picard
      spotify
      vesktop
      ani-cli
      manga-tui
      mkvtoolnix
      qbittorrent
      drum-machine
      github-desktop
      element-desktop
      telegram-desktop
      kdePackages.kdenlive

      (wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          input-overlay
          obs-backgroundremoval
        ];
      })

      (vscode-with-extensions.override {
        vscodeExtensions = with vscode-extensions; [
          # languages
          golang.go
          ms-python.python
          # linters / formatters / related
          ms-python.pylint
          ms-python.vscode-pylance
          jeff-hykin.better-nix-syntax
          # misc
          yzane.markdown-pdf
          yy0931.vscode-sqlite3-editor
        ];
      })
    ];
  } // passwordConfiguration;

  programs = {
    git.enable = true;
    nix-ld.enable = true;
    starship.enable = true;

    fzf = { keybindings = true; };

    gamescope = {
      enable = true;
      capSysNice = true;
    };

    steam = {
      enable = true;
      gamescopeSession.enable = true;
      dedicatedServer.openFirewall = true;
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };

    brave = {
      enable = true;

      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # BitWarden
        "mlomiejdfkolichcflejclcbmpeaniij" # Ghostery
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
      ];

      policies = {
        brave = {
          BraveNewsDisabled = true;
          BraveAIChatEnabled = false;
          PasswordManagerEnabled = false;
          AutofillAddressEnabled = false;
          MetricsReportingEnabled = false;
          BrowserAddPersonEnabled = false;
          DnsOverHttpsMode = "secure";
          DnsOverHttpsTemplates =
            "https://security.cloudflare-dns.com/dns-query{?dns}";
          ClearBrowsingDataOnExitList = [
            "cached_images_and_files"
            "site_settings"
            "browsing_history"
            "download_history"
          ];
        };
      };
    };

    chromium = {
      enable = true;

      # Optional: Try with a custom chromium build
      # package = pkgs.ungoogled-chromium;

      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "gcbommkclmclpchllfjekcdonpmejbdp" # HTTPS Everywhere
        "mbniclmhobmnbdlbpiphghaielnnpgdp" # Lightshot
      ];

      homepageLocation = "https://nixos.org";

      defaultSearchProviderEnabled = true;
      defaultSearchProviderSearchURL =
        "https://duckduckgo.com/?q={searchTerms}";
      defaultSearchProviderSuggestURL =
        "https://duckduckgo.com/ac/?q={searchTerms}&type=list";

      # Enterprise policies (general)
      extraOpts = {
        "PasswordManagerEnabled" = false;
        "BrowserSignin" = 0;
        "CloudPrintProxyEnabled" = false;
        "BookmarkBarEnabled" = true;
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [ "en-US" "de" ];
      };

      # First-run settings
      initialPrefs = {
        "first_run_tabs" = [ "https://nixos.org/" "https://search.nixos.org/" ];
        "translate_enabled" = false;
      };

      # Chromium-specific policies (merged after extraOpts)
      policies = {
        chromium = {
          "SyncDisabled" = true;
          "BrowserAddPersonEnabled" = false;
          "MetricsReportingEnabled" = false;
        };
      };
    };

    firefox = {
      enable = false;
      languagePacks = [ "en-US" ];
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar =
          "newtab"; # alternatives: "never", "always" or "newtab"
        DisplayMenuBar =
          "default-on"; # alternatives: "default-off", "always", "never" or "default-on"

        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };

        SanitizeOnShutdown = {
          Cache = false;
          Cookies = false;
          FormData = true;
          History = true;
          Sessions = false;
          SiteSettings = true;
          Locked = true;
        };

        # ---- EXTENSIONS ----
        # Check about:support for extension/add-on ID strings.
        # Valid strings for installation_mode are "allowed", "blocked",
        # "force_installed" and "normal_installed".
        ExtensionSettings = {
          "*".installation_mode =
            "blocked"; # blocks all addons except the ones specified below
          # uBlock Origin:
          "uBlock0@raymondhill.net" = {
            install_url =
              "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          # Privacy Badger:
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url =
              "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };
          # BitWarden Password Manager
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url =
              "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
        };
      };
    };

    bash = {
      interactiveShellInit = ''
        shopt -s autocd
        shopt -s cdspell

        set completion-ignore-case on

        pkg_builder() {
          if [[ -f "$1" ]]; then
            nix-build -E "with import <nixpkgs> {}; callPackage $1 {}"
          else
            echo 'no file specified'
          fi
        }

        nixopt() {
          nix-shell -p nixos-option --run "nixos-option $*"
        }

        nix-get-attr() {
          local ATTR_PATH="$1"
          local NIX_FILE_PATH="$''${2:-<nixpkgs>}"

          local EXPRESSION="with import $''${NIX_FILE_PATH} {}; $''${ATTR_PATH}"

          nix-instantiate --eval --expr "$EXPRESSION" --raw
        }
      '';

      shellAliases = {
        ".." = "cd ..";
        "editfile" = "nvim $(fzf --style full)";
        "unshallow-fetch" = "git fetch --unshallow";
        "nrb" = "nixos-rebuild boot --sudo --upgrade-all";
        "nrs" = "nixos-rebuild switch --sudo --upgrade-all";
        "nix-clean" = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
        "configuration.nix" = "sudoedit /etc/nixos/configuration.nix";
        "hardware-configuration.nix" =
          "sudoedit /etc/nixos/hardware-configuration.nix";
      };
    };
  };

  environment = { systemPackages = (with pkgs; [ gparted ]); };

  nixpkgs.config.allowUnfree = true;

  nix = {
    optimise.automatic = true;
    settings.auto-optimise-store = true;

    gc = {
      dates = "daily";
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  system.stateVersion = "25.11";

}
