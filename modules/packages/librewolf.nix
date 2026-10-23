{
  self,
  inputs,
  ...
}: {
  perSystem = {
    lib,
    pkgs,
    inputs',
    ...
  }: let
    addons = inputs'.firefox-addons.packages;

    forceInstall = addon: {
      install_url = "file://${addon}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addon.addonId}.xpi";
      installation_mode = "force_installed";
    };

    lock = value: {
      Value = value;
      Status = "locked";
    };

    policies = {
      SanitizeOnShutdown = {
        Exceptions = [
          "https://accounts.google.com"
          "https://www.google.com"
          "https://youtube.com"
          "https://github.com"
        ];
      };

      SearchEngines = {
        Default = "NonAIGoogle";
        Add =
          map (engine: {
            Name = engine.name;
            URLTemplate = engine.url;
            Alias = engine.alias;
            Method = "GET";
          })
          [
            {
              name = "NonAIGoogle";
              alias = "@gg";
              url = "https://www.google.com/search?udm=14&q={searchTerms}";
            }
            {
              name = "Youtube";
              alias = "@yt";
              url = "https://www.youtube.com/results?search_query={searchTerms}";
            }
            {
              name = "Nix Packages";
              alias = "@np";
              url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
            }
            {
              name = "Nix Options";
              alias = "@no";
              url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
            }
            {
              name = "NixOS Wiki";
              alias = "@nw";
              url = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
            }
            {
              name = "Home Manager Options";
              alias = "@nh";
              url = "https://home-manager-options.extranix.com/?release=master&query={searchTerms}";
            }
          ];

        Remove = [
          "Mojeek"
          "Brave"
          "Searx"
          "DuckDuckGo No-AI"
          "Startpage"
        ];
      };

      AppAutoUpdate = false;
      BackgroundAppUpdate = false;
      NoDefaultBookmarks = true;

      # Feature Disabling
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSetDesktopBackground = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;

      # Access Restrictions
      BlockAboutConfig = false;
      BlockAboutProfiles = true;
      # BlockAboutSupport = true;

      # UI and Behavior
      DisplayMenuBar = "never";
      DontCheckDefaultBrowser = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      UserMessaging = {
        SkipOnboarding = true;
        WhatsNew = false;
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        MoreFromMozilla = false;
        FirefoxLabs = false;
      };
      HardwareAcceleration = false;
      OfferToSaveLogins = false;

      # AI
      AIControls = {
        Enabled = false;
        Chatbot = false;
        LinkPreviews = false;
        TabGroups = false;
        Locked = true;
      };

      # Security
      AutofillCreditCardEnabled = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      ExtensionSettings =
        {"*".installation_mode = "blocked";}
        // builtins.listToAttrs (map (addon: {
            name = addon.addonId;
            value = forceInstall addon;
          }) (with addons; [
            istilldontcareaboutcookies
            # floccus
            ublock-origin
            bitwarden
            leechblock-ng
          ]));

      "3rdparty".Extensions = {
        "${addons.ublock-origin.addonId}".adminSettings.userSettings = {
          uiTheme = "dark";
          uiAccentCustom = true;
          uiAccentCustom0 = "#${self.globals.theme.palette.base0E}";
          cloudStorageEnabled = false;
        };

        "${addons.bitwarden.addonId}" = {
          environment = {
            base = "https://vault.taildevourer.com";
          };
        };
      };

      Preferences = {
        "browser.contentblocking.category" = lock "strict";

        "sidebar.revamp" = lock true;
        "sidebar.verticalTabs" = lock true;
        "sidebar.main.tools" = lock "${addons.bitwarden.addonId}";

        # clear up nav-bar
        "browser.uiCustomization.state" = lock ''
          {
             "placements":{
                "nav-bar":[
                   "back-button",
                   "forward-button",
                   "stop-reload-button",
                   "customizableui-special-spring1",
                   "vertical-spacer",
                   "urlbar-container",
                   "customizableui-special-spring2",
                   "downloads-button",
                   "open-file-button",
                   "fxa-toolbar-menu-button",
                   "reset-pbm-toolbar-button",
                   "unified-extensions-button",
                   "ublock0_raymondhill_net-browser-action",
                   "alltabs-button",
                   "smartwindow-group-tabs-button",
                   "ai-window-toggle"
                ]
             }
          }
        '';

        "layers.acceleration.force-enabled" = lock true;
        "browser.toolbars.bookmarks.visibility" = lock "never";
      };
    };

    librewolfWrapped = pkgs.wrapFirefox pkgs.librewolf-unwrapped {
      inherit (pkgs.librewolf-unwrapped) extraPrefsFiles extraPoliciesFiles;
      libName = "librewolf";
      extraPolicies = policies;
      extraPrefs = ''
        lockPref("browser.aboutConfig.showWarning", false);
        lockPref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

        // Set UI density to normal
        lockPref("browser.uidensity", 0);

        // Enable SVG context-propertes
        lockPref("svg.context-properties.content.enabled", true);

        // Disable private window dark theme
        lockPref("browser.theme.dark-private-windows", false);

        // Enable rounded bottom window corners
        lockPref("widget.gtk.rounded-bottom-corners.enabled", true);

        // Middle mouse paste
        lockPref("middlemouse.paste", false);

        // Disable backups as it causes warnings.
        // Possibly because it tries to access root directory.
        lockPref("browser.backup.enabled", false);
        lockPref("browser.backup.scheduled.enabled", false);
        lockPref("browser.backup.archive.enabled", false);
        lockPref("browser.backup.restore.enabled", false);

        // Disable translation popup.
        lockPref("browser.translations.automaticallyPopup", false);
      '';
    };

    profile = pkgs.linkFarm "librewolf-profile-skeleton" [
      {
        name = "chrome/userChrome.css";
        path = pkgs.writeText "userChrome.css" ''
          @import "${inputs.firefox-gnome-theme}/userChrome.css";
          ${self.css.librewolf (inputs.colors.lib.withHash self.globals.theme.palette)}
        '';
      }
      {
        name = "chrome/userContent.css";
        path = pkgs.writeText "userContent.css" ''
          @import "${inputs.firefox-gnome-theme}/userContent.css";
          ${self.css.librewolf (inputs.colors.lib.withHash self.globals.theme.palette)}

          @-moz-document url("about:newtab"), url("about:home") {
            /* Wallpaper */
            body {
              background-image: url("file://${../../resources/wallpapers/bain_ning_bing_and_fang_yuan.png}") !important;
              background-position: center center !important;
              background-size: cover !important;
              background-repeat: no-repeat !important;
            }

            /* Center Search Bar */
            .search-wrapper {
              position: fixed !important;
              top: 50% !important;
              left: 50% !important;
              transform: translate(-50%, -50%) !important;
            }

            /* Disable Logo */
            .logo-and-wordmark-wrapper {
              display:none !important;
            }

            /* Disable Home Customize Button */
            .open-customization-button {
              display:none !important;
            }
          }
        '';
      }
    ];

    fontsConf = pkgs.makeFontsConf {
      fontDirectories = [
        pkgs.noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-cjk-serif
        pkgs.noto-fonts-color-emoji
      ];
    };
  in {
    packages = {
      librewolf = let
        save = pkgs.writeShellScript "save" ''
          [[ -f "$1" ]] || exit 0

          if [[ "$#" -ne 2 ]]; then
            echo "Usage: save <profile-db> <stored-db>" >&2
            exit 1
          fi

          tmp=$(mktemp)
          trap 'rm -rf \$tmp' EXIT

          ${lib.getExe pkgs.sqlite} "$1" "VACUUM INTO '$tmp'"

          mv "$tmp" "$2"
        '';

        load = pkgs.writeShellScript "load" ''
          if [[ "$#" -ne 2 ]]; then
            echo "Usage: load <profile-db> <stored-db>" >&2
            exit 1
          fi

          if [[ -f "$2" ]]; then
            cp "$2" "$1"
          fi
        '';
      in
        pkgs.symlinkJoin {
          name = "librewolf";
          paths = [librewolfWrapped];
          postBuild = ''
            mv $out/bin/librewolf $out/bin/.librewolf

            cat > $out/bin/librewolf << EOF
            #!${pkgs.runtimeShell}
            export FONTCONFIG_FILE=${fontsConf}

            state="\$HOME/.librewolf"
            mkdir -p "\$state"

            dir=\$(mktemp -d -t librewolf.XXXXXX)
            trap '${save} "\$dir/cookies.sqlite" "\$state/cookies.sqlite"; rm -rf "\$dir"' EXIT

            cp -rL --no-preserve=mode ${profile}/. "\$dir"
            ${load} "\$dir/cookies.sqlite" "\$state/cookies.sqlite"

            $out/bin/.librewolf --profile "\$dir" "\$@"
            EOF

            chmod +x $out/bin/librewolf
          '';

          meta = {
            mainProgram = "librewolf";
          };
        };
    };
  };

  flake = {
    css.librewolf = theme: ''
      :root {
        --gnome-palette-blue-1: ${theme.base0D};
        --gnome-palette-blue-2: ${theme.base0D};
        --gnome-palette-blue-3: ${theme.base0D};
        --gnome-palette-blue-4: ${theme.base0D};
        --gnome-palette-blue-5: ${theme.base0D};
        --gnome-palette-green-1: ${theme.base0B};
        --gnome-palette-green-2: ${theme.base0B};
        --gnome-palette-green-3: ${theme.base0B};
        --gnome-palette-green-4: ${theme.base0B};
        --gnome-palette-green-5: ${theme.base0B};
        --gnome-palette-yellow-1: ${theme.base0A};
        --gnome-palette-yellow-2: ${theme.base0A};
        --gnome-palette-yellow-3: ${theme.base0A};
        --gnome-palette-yellow-4: ${theme.base0A};
        --gnome-palette-yellow-5: ${theme.base0A};
        --gnome-palette-orange-1: ${theme.base09};
        --gnome-palette-orange-2: ${theme.base09};
        --gnome-palette-orange-3: ${theme.base09};
        --gnome-palette-orange-4: ${theme.base09};
        --gnome-palette-orange-5: ${theme.base09};
        --gnome-palette-red-1: ${theme.base08};
        --gnome-palette-red-2: ${theme.base08};
        --gnome-palette-red-3: ${theme.base08};
        --gnome-palette-red-4: ${theme.base08};
        --gnome-palette-red-5: ${theme.base08};
        --gnome-palette-purple-1: ${theme.base0E};
        --gnome-palette-purple-2: ${theme.base0E};
        --gnome-palette-purple-3: ${theme.base0E};
        --gnome-palette-purple-4: ${theme.base0E};
        --gnome-palette-purple-5: ${theme.base0E};
        --gnome-palette-brown-1: ${theme.base0F};
        --gnome-palette-brown-2: ${theme.base0F};
        --gnome-palette-brown-3: ${theme.base0F};
        --gnome-palette-brown-4: ${theme.base0F};
        --gnome-palette-brown-5: ${theme.base0F};
        --gnome-palette-light-1: ${theme.base05};
        --gnome-palette-light-2: ${theme.base05};
        --gnome-palette-light-3: ${theme.base05};
        --gnome-palette-light-4: ${theme.base05};
        --gnome-palette-light-5: ${theme.base05};
        --gnome-palette-dark-1: ${theme.base05};
        --gnome-palette-dark-2: ${theme.base05};
        --gnome-palette-dark-3: ${theme.base05};
        --gnome-palette-dark-4: ${theme.base05};
        --gnome-palette-dark-5: ${theme.base05};


        /* Accent */
        --gnome-accent-bg: ${theme.base0D};
        --gnome-accent: ${theme.base0D};
        --gnome-accent-bg-hover: ${theme.base0D};
        --gnome-accent-hover: ${theme.base0D};

        /* Colors */
        --gnome-destructive-bg: var(--gnome-palette-red-3);
        --gnome-success-bg: var(--gnome-palette-green-5);
        --gnome-warning-bg: var(--gnome-palette-yellow-3);
        --gnome-error-bg: var(--gnome-palette-red-4);

        --gnome-toolbar-star-button: var(--gnome-palette-yellow-1);

        /* Window */
        --gnome-window-background: ${theme.base00};
        --gnome-window-color: ${theme.base05};
        --gnome-view-background: ${theme.base00};
        --gnome-sidebar-background: ${theme.base01} !important;
        --gnome-secondary-sidebar-background: ${theme.base01} !important;

        /* UI Elements */
        --gnome-entry-background: color-mix(in srgb, ${theme.base01} 40%, ${theme.base02} 100%);

        /* Card */
        --gnome-card-background: ${theme.base01};
        --gnome-card-shade-color: rgba(0, 0, 0, 0.07);

        /* Menu */
        --gnome-menu-background: ${theme.base01};

        /* Headerbar */
        --gnome-headerbar-background: ${theme.base01};
        --gnome-headerbar-shade-color: rgba(0, 0, 0, 0.07);

        /* Toolbar */
        --toolbox-textcolor: ${theme.base05} !important;
        --toolbox-textcolor-inactive: ${theme.base05} !important;
        --toolbar-color: ${theme.base05} !important;
        --gnome-toolbar-icon-fill: ${theme.base05};

        /* Tabs */
        --gnome-tabbar-tab-hover-background: color-mix(in srgb, ${theme.base01} 50%, ${theme.base02} 52%);
        --gnome-tabbar-tab-active-background: color-mix(in srgb, ${theme.base01} 40%, ${theme.base02} 100%);
        --gnome-tabbar-tab-active-background-contrast: ${theme.base02};
        --gnome-tabbar-tab-active-hover-background: color-mix(in oklab, ${theme.base01} 5.8%, ${theme.base02} 100%);

        --gnome-tabbar-identity-color-blue: var(--gnome-palette-blue-2);
        --gnome-tabbar-identity-color-green: var(--gnome-palette-green-1);
        --gnome-tabbar-identity-color-yellow: var(--gnome-palette-yellow-2);
        --gnome-tabbar-identity-color-orange: var(--gnome-palette-orange-3);
        --gnome-tabbar-identity-color-red: var(--gnome-palette-red-1);
        --gnome-tabbar-identity-color-purple: var(--gnome-palette-purple-1);

        /* Private Tabs */
        --gnome-private-wordmark: ${theme.base04};
        --gnome-private-in-content-page-background: ${theme.base00};
        --gnome-private-text-primary-color: ${theme.base06};

        &:-moz-window-inactive {
          --gnome-tabbar-tab-hover-background: var(--gnome-tabbar-tab-hover-background);
          --gnome-tabbar-tab-active-background: color-mix(in oklab, ${theme.base01} 50%, ${theme.base02} 77.5%);
          --gnome-entry-background: color-mix(in oklab, ${theme.base01} 50%, ${theme.base02} 77.5%);
        }
      }
    '';
  };
}
