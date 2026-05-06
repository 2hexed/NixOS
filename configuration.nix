{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  arrServiceGroup = "qbittorrent";
  arrServiceACL = "d:group:${arrServiceGroup}:rwx,group:${arrServiceGroup}:rwx";

  arrServiceConfig = {
    # Directory = User
    "Movies" = "radarr";
    "Music" = "lidarr";
    "Shows" = "sonarr";
    "Porn" = "whisparr";
    "Downloads" = arrServiceGroup;
  };

  laptopRules = map (node: "z /sys/bus/platform/drivers/ideapad_acpi/*/${node} 0664 root users") [
    "conservation_mode"
    "camera_power"
    "fan_mode"
    "fn_lock"
    "touchpad"
    "usb_charging"
  ];

  mediaRules = [
    "Z /media 2775 ${arrServiceGroup} ${arrServiceGroup} -"
    "A /media - - - - ${arrServiceACL}"
  ]
  ++ (builtins.concatLists (
    builtins.attrValues (
      builtins.mapAttrs (dir: owner: [
        "Z /media/${dir} 2775 ${owner} ${arrServiceGroup} -"
        "A /media/${dir} - - - - ${arrServiceACL}"
      ]) arrServiceConfig
    )
  ));

  flattenDconf =
    path: attrs:
    lib.flatten (
      lib.mapAttrsToList (
        key: value:
        if builtins.isAttrs value && !(lib.gvariant.isGVariant value) then
          flattenDconf "${path}/${key}" value
        else
          "${path}/${key}"
      ) attrs
    );

  gnomeUserExtensions = with pkgs.gnomeExtensions; [
    caffeine
    appindicator
    blur-my-shell
    ideapad-controls
    removable-drive-menu
    night-theme-switcher
  ];

  sharedPolicies = {
    ShowHomeButton = true;
    BookmarkBarEnabled = false;
    DNSOverHttpsMode = "secure";
    DNSOverHttpsTemplates = "https://cloudflare-dns.com/dns-query";
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    # NewTabPageLocation = "";
    HomepageLocation = "http://localhost:8081";
    HomepageIsNewTabPage = false;
    PasswordManagerEnabled = false;
    ClearBrowsingDataOnExitList = [
      "site_settings"
      "download_history"
    ];
  };

  dconfUserSettings = {
    # "org/gnome/desktop/remote-desktop/rdp" = {
    #    screen-share-mode = "extend";
    # };
    "org/gnome/desktop/peripherals/touchpad" = {
      send-events = "disabled-on-external-mouse";
    };
    "org/gnome/desktop/media-handling" = {
      automount = false;
      automount-open = false;
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<control><alt>t";
      command = "kgx";
      name = "console";
    };
    "de/haeckerfelix/shortwave" = {
      recording-mode = "nothing";
      notifications = true;
    };
    "org/gnome/desktop/interface" = {
      text-scaling-factor = 1.25;
    };
    "org/gnome/shell/extensions/ideapad-controls" = {
      tray-location = false;
    };
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      force-light-text = true;
    };
    "org/gnome/desktop/privacy" = {
      remove-old-temp-files = true;
      remove-old-trash-files = true;
      old-files-age = lib.gvariant.mkUint32 7;
      recent-files-max-age = lib.gvariant.mkInt32 7;
    };
    "org/gnome/shell/extensions/nightthemeswitcher/time" = {
      sunrise = 6.0;
      sunset = 20.0;
    };
    "org/gnome/nautilus/preferences" = {
      show-hidden = true;
      click-policy = "single";
      show-create-link = true;
      show-delete-permanently = true;
    };
    "org/gnome/shell" = {
      disable-user-extensions = false;
      disable-extension-version-validation = true;
      enabled-extensions = map (ext: ext.extensionUuid) gnomeUserExtensions;
      favorite-apps = [
        "org.gnome.snapshot.desktop"
        "google-chrome.desktop"
        "org.gnome.calendar.desktop"
        "org.gnome.music.desktop"
        "org.gnome.nautilus.desktop"
        "org.gnome.texteditor.desktop"
        "org.gnome.console.desktop"
        "antigravity.desktop"
        "element-desktop.desktop"
      ];
    };
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./google-chrome.nix
  ];

  zramSwap.enable = true;
  time.timeZone = "Asia/Kolkata";
  nixpkgs.config.allowUnfree = true;
  systemd.tmpfiles.rules = mediaRules ++ laptopRules;
  # disabledModules = [ "services/desktops/blueman.nix" ];

  nix = {
    optimise.automatic = true;
    settings.auto-optimise-store = true;

    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  fonts = {
    packages =
      (with pkgs; [
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
      ])
      ++ (with pkgs.nerd-fonts; [ symbols-only ]);
  };

  boot = {
    tmp.cleanOnBoot = true;

    loader = {
      timeout = 3;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "snowflake-ideapad";

    firewall = {
      allowedTCPPorts = [
        0800 # kodi remote
        3000
      ];
      allowedUDPPorts = [
        9777 # kodi remote
        3000
      ];
    };

    networkmanager = {
      enable = true;
      # wifi.macaddress = "random";
      ethernet.macAddress = "random";
    };
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    nvidia = {
      open = true;
      nvidiaPersistenced = true;
      package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;

      prime = {
        sync.enable = true;
        intelBusId = "pci:0:2:0";
        nvidiaBusId = "pci:1:0:0";
      };
    };
  };

  services = {
    fstrim.enable = true;
    usbmuxd.enable = true;
    prowlarr.enable = true;
    flaresolverr.enable = true;
    pulseaudio.enable = true; # required by xfce
    spice-vdagentd.enable = true;
    journald.storage = "volatile";
    gnome.gnome-keyring.enable = true;
    desktopManager.gnome.enable = true;
    desktopManager.gnome.flashback.enableMetacity = true;

    getty = {
      autologinUser = "n";
      autologinOnce = true;
    };

    logind.settings = {
      Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };
    };

    dashnix = {
      enable = true;
      openFirewall = true;
      watchedServices = [
        "jellyfin"
        "qbittorrent"
        "jellyseerr"
        "prowlarr"
        "bazarr"
        "whisparr"
        "sonarr"
        "radarr"
        "lidarr"
      ];
    };

    # ollama = {
    #   enable = true;
    #   package = pkgs.ollama-cuda;
    #   acceleration = "cuda";
    #   loadModels = [ "qwen2.5:7b" ]; # [ "deepseek-r1:7b" ];
    #   syncModels = true;

    #   environmentVariables = {
    #     OLLAMA_NUM_PARALLEL = "1";
    #     OLLAMA_MAX_LOADED_MODELS = "1";
    #   };
    # };

    xrdp = {
      enable = true;
      openFirewall = true;
      defaultWindowManager = "exec ${pkgs.dbus}/bin/dbus-run-session ${pkgs.xfce.xfce4-session}/bin/xfce4-session";
    };

    openssh = {
      enable = true;
      settings = {
        # PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;

      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    jellyseerr = {
      enable = true;
      openFirewall = true;
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    bazarr = {
      enable = true;
      group = arrServiceGroup;
    };

    whisparr = {
      enable = true;
      group = arrServiceGroup;
    };

    sonarr = {
      enable = true;
      group = arrServiceGroup;
    };

    radarr = {
      enable = true;
      group = arrServiceGroup;
    };

    lidarr = {
      enable = true;
      group = arrServiceGroup;
    };

    qbittorrent = {
      enable = true;
      group = arrServiceGroup;

      serverConfig = {
        BitTorrent = {
          Session = {
            MaxRatio = 0;
            GlobalMaxRatio = 0;
            MaxRatioEnabled = true;
            MaxActiveTorrents = 10;
            MaxActiveDownloads = 10;
            ShareLimitAction = "Remove";
            AddTorrentToTopOfQueue = true;
            DefaultSavePath = "/media/Downloads";
            TorrentContentLayout = "Subfolder";
          };
        };

        Preferences = {
          WebUI = {
            AuthSubnetWhitelistEnabled = true;
            AuthSubnetWhitelist = "127.0.0.1/32, ::1/128";
          };
        };
      };
    };

    xserver = {
      enable = false;
      enableTearFree = true;
      updateDbusEnvironment = true;
      desktopManager.xfce.enable = true;

      videoDrivers = [
        "nvidia"
      ];

      desktopManager.kodi = {
        enable = true;
        package = pkgs.kodi.withPackages (
          p: with p; [
            jellyfin
          ]
        );
      };
    };
  };

  users.users.n = {
    isNormalUser = true;
    description = "Nick";
    initialPassword = "nicepassword69"; # Run: mkpasswd

    extraGroups = [
      "audio"
      "video"
      "render"
      "wheel"
      "networkmanager"
    ];

    packages =
      with pkgs;
      [
        xclip # x11 clipboard
        wl-clipboard # Wayland clipboard

        xdg-utils
        peazip

        smassh
        vesktop
        ripgrep
        ani-cli
        anydesk
        lmstudio
        flowblade
        shortwave
        manga-tui
        vscode-fhs
        antigravity
        video-trimmer
        github-desktop
        bitwarden-desktop

        # xfce4-whiskermenu-plugin
        xfce.xfce4-whiskermenu-plugin
      ]
      ++ gnomeUserExtensions;
  };

  programs = {
    git.enable = true;
    nix-ld.enable = true;
    starship.enable = true;
    seahorse.enable = true;
    gitgetter.enable = true;

    fzf = {
      keybindings = true;
    };

    obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      plugins = with pkgs.obs-studio-plugins; [
        input-overlay
        obs-backgroundremoval
      ];
    };

    # vscode = {
    #   enable = true;
    #   package = pkgs.vscode-fhs;

    #   # enterprisepolicies = {
    #   #   "telemetrylevel" = "off";
    #   #   "updatemode" = "none";
    #   # };

    #   # extensions = with pkgs.vscode-extensions; [
    #   #   # languages
    #   #   golang.go
    #   #   ms-python.python
    #   #   mads-hartmann.bash-ide-vscode
    #   #   # linters / formatters / related
    #   #   ms-python.pylint
    #   #   ms-python.vscode-pylance
    #   #   jeff-hykin.better-nix-syntax
    #   #   # misc
    #   #   yzane.markdown-pdf
    #   #   yy0931.vscode-sqlite3-editor
    #   # ];
    # };

    google-chrome = {
      enable = true;

      # commandLineArgs = [
      #   "--disable-gpu"
      #   "--enable-features=VaapiVideoDecoder"
      # ];

      extensions = [
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # ublock origin lite
        "omghfjlpggmjjaagoclmmobgdodcjboh" # browsec
        "mbniclmhobmnbdlbpiphghaielnnpgdp" # lightshot
        "mlomiejdfkolichcflejclcbmpeaniij" # ghostery
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
      ];

      policies = sharedPolicies;
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      configure = {
        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [ catppuccin-nvim ];
        };
        customLuaRC = ''
          require("catppuccin").setup({ flavour = "mocha" })
          vim.cmd.colorscheme "catppuccin"

          -- Essential Settings
          vim.opt.number = true         -- Show line numbers
          vim.opt.relativenumber = true -- Great for jumping around
          vim.opt.cursorline = true     -- Highlight current line
          vim.opt.termguicolors = true  -- Better colors

          -- (Requires 'wl-copy' for Wayland or 'xclip' for X11)
          vim.opt.clipboard = "unnamedplus"

          -- Smooth Tweak: Identing
          vim.opt.tabstop = 2
          vim.opt.shiftwidth = 2
          vim.opt.expandtab = true
        '';
      };
    };

    dconf = {
      enable = true;
      profiles.user.databases = [
        {
          locks = flattenDconf "" dconfUserSettings;
          settings = dconfUserSettings;
        }
      ];

      profiles.gdm.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              text-scaling-factor = 1.25;
            };
          };
        }
      ];
    };

    # brave = {
    #   enable = true;

    #   extensions = [
    #     "mlomiejdfkolichcflejclcbmpeaniij" # ghostery
    #     "dhdgffkkebhmkfjojejmpbldmpobfkfo" # tampermonkey
    #     "hlkenndednhfkekhgcdicdfddnkalmdm" # cookie editor
    #     "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
    #   ];

    #   policies = sharedPolicies;
    # };

    # chromium = {
    #   enable = true;
    #   # package = pkgs.ungoogled-chromium;

    #   extensions = [
    #     "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
    #     "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
    #     "mbniclmhobmnbdlbpiphghaielnnpgdp" # lightshot
    #   ];

    #   # first-run settings
    #   initialprefs = {
    #     "first_run_tabs" = [
    #       "https://nixos.org/"
    #       "https://search.nixos.org/"
    #     ];
    #     # "translate_enabled" = false;
    #   };

    #   # chromium-specific policies (merged after extraopts)
    #   policies = sharedPolicies;
    # };

    bash = {
      shellAliases = {
        ".." = "cd ..";
        "e" = "''$EDITOR";
        "nix_clean" = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
        "flake.nix" = "sudoedit /etc/nixos/flake.nix";
        "configuration.nix" = "sudoedit /etc/nixos/configuration.nix";
        "hardware-configuration.nix" = "sudoedit /etc/nixos/hardware-configuration.nix";
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      bottom
      gparted
      (pkgs.callPackage /home/n/Documents/GitHub/synclyr2metadata/package.nix { })
    ];

    # interactiveShellInit = ''
    #   if [[ $(tty) == "/dev/tty1" ]]; then
    #     exec btm
    #   fi
    # '';

    gnome.excludePackages = with pkgs; [
      yelp
      geary
      epiphany
    ];
  };

  system.stateVersion = "25.11";
}
