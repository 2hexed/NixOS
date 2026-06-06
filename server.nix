{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  adminUsername = "admin";
  arrServiceGroup = "qbittorrent";
  arrServiceACL = "d:group:${arrServiceGroup}:rwx,group:${arrServiceGroup}:rwx";

  arrServiceConfig = {
    # DIR = USER
    "Movies" = "radarr";
    "Music" = "lidarr";
    "Shows" = "sonarr";
    "Porn" = "whisparr";
    "Downloads" = arrServiceGroup;
  };

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
in
{
  imports = [ inputs.snapcore.nixosModules.default ];

  systemd.tmpfiles.rules = mediaRules;
  networking.networkmanager.enable = true;

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  users.users.${adminUsername} = {
    isNormalUser = true;
    description = "Server Admin";
    initialPassword = "admin"; # Run: passwd or mkpasswd and set a password

    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      bottom
      xfce4-whiskermenu-plugin
    ];

    interactiveShellInit = ''
      if [[ "$(tty)" == "/dev/tty1" ]]; then
        exec btm
      fi
    '';
  };

  services = {
    prowlarr.enable = true;
    flaresolverr.enable = true;

    seerr = {
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

    getty = {
      autologinUser = adminUsername;
      autologinOnce = true;
    };

    xserver = {
      desktopManager.xfce.enable = true;
    };

    xrdp = {
      enable = true;
      openFirewall = true;
      defaultWindowManager = "exec ${pkgs.dbus}/bin/dbus-run-session ${pkgs.xfce4-session}/bin/xfce4-session";
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

    dashnix = {
      enable = true;
      openFirewall = true;

      watchedServices = [
        "jellyfin"
        "qbittorrent"
        "seerr"
        "prowlarr"
        "bazarr"
        "whisparr"
        "sonarr"
        "radarr"
        "lidarr"
      ];
    };

    # LAPTOPS ONLY
    logind.settings = {
      Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };
    };

    # ollama = {
    #   enable = true;
    #   package = pkgs.ollama-cuda;
    #   acceleration = "cuda";
    #   loadModels = [ "qwen3.5:2b" ]; # [ "qwen2.5:7b" ]; # [ "deepseek-r1:7b" ];
    #   syncModels = true;

    #   environmentVariables = {
    #     OLLAMA_NUM_PARALLEL = "1";
    #     OLLAMA_MAX_LOADED_MODELS = "1";
    #   };
    # };

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
  };
}
