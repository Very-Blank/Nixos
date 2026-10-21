{
  self,
  inputs,
  ...
}: {
  perSystem = {
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

    engine = name: alias: url: {
      Name = name;
      Alias = alias;
      URLTemplate = url;
      Method = "GET";
    };

    policies = {
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        Snippets = false;
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
      BlockAboutSupport = true;

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
      GenerativeAI = {
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
            floccus
            ublock-origin
            bitwarden
            leechblock-ng
          ]));

      WebsiteFilter = {
        Block = ["*://darkreader.org/help/*"];
      };

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

      SearchEngines = {
        Default = "NonAIGoogle";
        Add = [
          (engine "NonAIGoogle" "@gg" "https://www.google.com/search?udm=14&q={searchTerms}")
          (engine "Youtube" "@yt" "https://www.youtube.com/results?search_query={searchTerms}")
          (engine "Nix Packages" "@np" "https://search.nixos.org/packages?channel=unstable&query={searchTerms}")
          (engine "Nix Options" "@no" "https://search.nixos.org/options?channel=unstable&query={searchTerms}")
          (engine "NixOS Wiki" "@nw" "https://wiki.nixos.org/w/index.php?search={searchTerms}")
          (engine "Home Manager Options" "@nh" "https://home-manager-options.extranix.com/?release=master&query={searchTerms}")
        ];
      };

      Preferences = {
        "browser.contentblocking.category" = lock "strict";

        "extensions.pocket.enabled" = lock false;
        "extensions.screenshots.disabled" = lock true;

        "browser.topsites.contile.enabled" = lock false;
        "browser.formfill.enable" = lock false;

        "browser.search.suggest.enabled" = lock false;
        "browser.search.suggest.enabled.private" = lock false;
        "browser.urlbar.suggest.searches" = lock false;
        "browser.urlbar.showSearchSuggestionsFirst" = lock false;
        "browser.urlbar.update2.engineAliasRefresh" = lock true;

        "browser.newtabpage.activity-stream.default.sites" = lock "";
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock false;
        "browser.newtabpage.activity-stream.showSponsored" = lock false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock false;
        "browser.newtabpage.activity-stream.showWeather" = lock false;
        "browser.newtabpage.activity-stream.system.showWeather" = lock false;
        "browser.newtabpage.activity-stream.system.showWeatherOptIn" = lock false;
        "browser.newtabpage.activity-stream.widgets.system.enabled" = lock false;
        "browser.newtabpage.activity-stream.widgets.lists.enabled" = lock false;
        "browser.newtabpage.activity-stream.widgets.focusTimer.enabled" = lock false;

        "sidebar.revamp" = lock true;
        "sidebar.verticalTabs" = lock true;
        "sidebar.verticalTabs.dragToPinPromo.dismissed" = lock true;
        "sidebar.main.tools" = lock "bookmarks,${addons.bitwarden.addonId}";

        "layers.acceleration.force-enabled" = lock true;

        "middlemouse.paste" = lock false;
        "browser.toolbars.bookmarks.visibility" = lock "never";

        "extensions.InstallTrigger.enabled" = lock false;
      };
    };

    firefoxWrapped = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      extraPolicies = policies;
    };

    profile = pkgs.linkFarm "firefox-profile-skeleton" [
      {
        name = "user.js";
        path = pkgs.writeText "user.js" ''
          user_pref("browser.aboutConfig.showWarning", false);
          user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

          // Set UI density to normal
          user_pref("browser.uidensity", 0);

          // Enable SVG context-propertes
          user_pref("svg.context-properties.content.enabled", true);

          // Disable private window dark theme
          user_pref("browser.theme.dark-private-windows", false);

          // Enable rounded bottom window corners
          user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
        '';
      }
      {
        name = "chrome/userChrome.css";
        path = pkgs.writeText "userChrome.css" ''
          @import "${inputs.firefox-gnome-theme}/userChrome.css";
          ${self.css.firefox (inputs.colors.lib.withHash self.globals.theme.palette)}
        '';
      }
      {
        name = "chrome/userContent.css";
        path = pkgs.writeText "userContent.css" ''
          @import "${inputs.firefox-gnome-theme}/userContent.css";
          ${self.css.firefox (inputs.colors.lib.withHash self.globals.theme.palette)}
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
      firefox = pkgs.symlinkJoin {
        name = "firefox";
        paths = [firefoxWrapped];
        postBuild = ''
          mv $out/bin/firefox $out/bin/.firefox

          cat > $out/bin/firefox << EOF
          #!${pkgs.runtimeShell}
          export FONTCONFIG_FILE=${fontsConf}

          dir=\$(mktemp -d -t firefox.XXXXXX)
          trap 'rm -rf \$dir' EXIT

          cp -rL --no-preserve=mode ${profile}/. "\$dir"

          if [[ "\$#" -ne 0 ]]; then
            $out/bin/.firefox --profile "\$dir" "\$@"
          else
            $out/bin/.firefox --profile "\$dir"
          fi
          EOF

          chmod +x $out/bin/firefox
        '';

        meta = {
          mainProgram = "firefox";
        };
      };
    };
  };

  flake = {
    css.firefox = theme: ''
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

        @-moz-document url(chrome://browser/content/browser.xul), url(about:newtab), url(about:home) {
          .personalizeButtonWrapper {
            display:none !important;
          }
        }
      }
    '';
  };
}
