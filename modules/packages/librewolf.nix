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
  in {
    packages.librewolf = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.librewolf module;

      addons = inputs'.firefox-addons.packages;

      makeUUID = value: let
        hash = lib.hashString "sha256" ("H9wihqDhg4mH0Jq1YaMXK7Wqc/134+79J/8gkXOstXs" + value);
      in "${lib.substring 0 8 hash}-${lib.substring 8 4 hash}-4${lib.substring 13 3 hash}-a${lib.substring 17 3 hash}-${lib.substring 20 12 hash}";

      policies = {
        SearchEngines = {
          Default = cfg.search.default;
          Add =
            lib.mapAttrsToList (name: value: {
              Name = name;
              URLTemplate = value.url;
              Alias = value.alias;
              Method = "GET";
            })
            cfg.search.engines;

          Remove = [
            "Mojeek"
            "Brave"
            "Searx"
            "DuckDuckGo No-AI"
            "Startpage"
          ];
        };

        SanitizeOnShutdown = {
          Exceptions = cfg.keepCookiesFor;
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

        ExtensionSettings = let
          forceInstall = addon: {
            install_url = "file://${addon}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addon.addonId}.xpi";
            installation_mode = "force_installed";
          };

          autoClose =
            pkgs.runCommand "auto-close.xpi" {
              manifest = ''
                {
                  "manifest_version": 2,
                  "name": "auto-close",
                  "version": "1.0",
                  "browser_specific_settings": { "gecko": { "id": "auto-close@local" } },
                  "permissions": ["tabs"],
                  "background": { "scripts": ["background.js"] }
                }
              '';
              background = ''
                const patterns = ${cfg.autoCloseTabs};

                browser.tabs.onUpdated.addListener(
                  (tabId) => browser.tabs.remove(tabId),
                  { urls: patterns, properties: ["url"] }
                );
              '';

              passAsFile = ["manifest" "background"];
              nativeBuildInputs = [pkgs.zip];
            } ''
              mkdir src
              cp $manifestPath src/manifest.json
              cp $backgroundPath src/background.js
              (cd src && zip -r "$out" .)
            '';
        in
          {"*".installation_mode = "blocked";}
          // lib.listToAttrs (map (extension: {
              name = addons.${extension.name}.addonId;
              value = forceInstall (addons.${extension.name});
            })
            cfg.extensions)
          // {
            "auto-close@local" = {
              installation_mode = "force_installed";
              install_url = "file://${autoClose}";
            };
          };

        "3rdparty".Extensions = lib.listToAttrs (
          map (
            extension: {
              name = addons.${extension.name}.addonId;
              value = extension.settings;
            }
          )
          (lib.filter (extension: extension.settings != null) cfg.extensions)
        );

        Preferences = let
          lock = value: {
            Value = value;
            Status = "locked";
          };
        in
          {
            "browser.contentblocking.category" = lock "strict";

            "sidebar.revamp" = lock true;
            "sidebar.verticalTabs" = lock true;
            "sidebar.main.tools" = lock (
              lib.concatStringsSep "," (map (extension: "${addons.${extension.name}.addonId}") (lib.filter (extension: extension.tool) cfg.extensions))
            );

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
          }
          // lib.optionalAttrs (cfg.background != null) {
            "browser.newtabpage.activity-stream.hideLogo" = lock false;
            "browser.newtabpage.activity-stream.showSearch" = lock false;
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

          lockPref("privacy.resistFingerprinting", false);
          lockPref("layout.css.prefers-color-scheme.content-override", 0);
          lockPref("browser.theme.content-theme", 0);
          lockPref("browser.theme.toolbar-theme", 0);

          lockPref("xpinstall.signatures.required", false);

          defaultPref("extensions.webextensions.uuids", ${
            lib.strings.toJSON (lib.strings.toJSON
              (lib.listToAttrs (
                map (
                  extension: {
                    name = addons.${extension.name}.addonId;
                    value = makeUUID addons.${extension.name}.addonId;
                  }
                )
                (lib.filter (extension: extension.keepData) cfg.extensions)
              )))
          });
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
              ${
              lib.optionalString (cfg.background != null) ''
                body {
                  background-image: url("file://${cfg.background}") !important;
                  background-position: center center !important;
                  background-size: cover !important;
                  background-repeat: no-repeat !important;
                }
              ''
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

      save = let
        uuids =
          map (
            extension: makeUUID addons.${extension.name}.addonId
          )
          (lib.filter (extension: extension.keepData) cfg.extensions);
      in
        pkgs.writeShellScript "save" ''
          set -euo pipefail

          if [[ "$#" -ne 2 ]]; then
            echo "Usage: save <profile-dir> <storage-dir>" >&2
            exit 1
          fi

          src="$1"
          dst="$2"
            
          [[ -f "$src"/cookies.sqlite ]] || exit 0

          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT

          ${lib.getExe pkgs.sqlite} "$src"/cookies.sqlite "VACUUM INTO '$tmp/cookies.sqlite'"

          if [[ -d "$src"/storage/default ]]; then
            for dir in "$src"/storage/default/https+++*; do
              db="$dir/ls/data.sqlite"
              [[ -f "$db" ]] || continue

              site="$(basename "$dir")"
              loc="$tmp"/storage/default/"$site"/ls

              mkdir -p "$loc"

              ${lib.getExe pkgs.sqlite} "$db" "VACUUM INTO '$loc/data.sqlite'"
            done
          fi
            
          for uuid in ${lib.escapeShellArgs uuids}; do
            ${saveExtensions} "$src"/storage/default/moz-extension+++"$uuid" "$tmp"

            for dir in "$src"/storage/default/moz-extension+++"$uuid"^userContextId=*; do
              ${saveExtensions} "$dir" "$tmp"
            done
          done

          ${lib.getExe pkgs.rsync} -a --delete "$tmp"/ "''${dst:?}"/
        '';

      saveExtensions = pkgs.writeShellScript "saveExtensions" ''
        set -euo pipefail

        if [[ "$#" -ne 2 ]]; then
          echo "Usage: save <extension-dir> <tmp-dir>" >&2
          exit 1
        fi

        dir="$1"
        name="$(basename "$dir")"
        tmp="$2"

        [[ -d "$dir" ]] || exit 0 

        ls_db="$dir"/ls/data.sqlite
        
        if [[ -f "$ls_db" ]]; then
          loc="$tmp"/storage/default/"$name"/ls
          mkdir -p "$loc"

          ${lib.getExe pkgs.sqlite} "$ls_db" "VACUUM INTO '$loc/data.sqlite'"
        fi

        [[ -d "$dir"/idb ]] || exit 0

        loc="$tmp"/storage/default/"$name"/idb
        mkdir -p "$loc"

        for folder in "$dir"/idb/*.files; do
          [[ -d "$folder" ]] || continue

          cp -r "$folder" "$loc/"
        done

        for db in "$dir"/idb/*.sqlite; do
          [[ -f "$db" ]] || continue

          ${lib.getExe pkgs.sqlite} "$db" "VACUUM INTO '$loc/$(basename "$db")'"
        done
      '';

      load = pkgs.writeShellScript "load" ''
        set -euo pipefail

        if [[ "$#" -ne 2 ]]; then
          echo "Usage: load <profile-dir> <stored-dir>" >&2
          exit 1
        fi

        src="$2"
        dst="$1"

        if [[ -d "$src" ]]; then
          cp -r "$src"/* "$dst"/
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

          hash=$(basename "$out" | cut -d- -f1)

          base="\$XDG_RUNTIME_DIR"
          [ -n "\$base" ] || base=/tmp
          dir="\$base/librewolf-\$hash"

          if [ -d "\$dir" ]; then
            exec $out/bin/.librewolf --profile "\$dir" "\$@"
          else
            mkdir -p -m 700 "\$dir"
            trap '${save} "\$dir" "\$state"; rm -rf "\$dir"' EXIT

            cp -rL --no-preserve=mode ${profile}/. "\$dir"
            ${load} "\$dir" "\$state"

            $out/bin/.librewolf --profile "\$dir" "\$@"
          fi

          EOF

          chmod +x $out/bin/librewolf
        '';

        meta = {
          mainProgram = "librewolf";
        };
      })
    {};
  };

  flake = {
    userModules.librewolfPersistent = user: {
      config = {
        preservation = {
          preserveAt."/persistent" = {
            users.${user} = {
              directories = [
                ".librewolf"
              ];
            };
          };
        };
      };
    };

    configOptions.librewolf = {
      lib,
      config,
      ...
    }: {
      options = {
        extensions = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.singleLineStr;
                description = ''
                  Name of the firefox addon.
                '';
              };

              settings = lib.mkOption {
                type = lib.types.nullOr lib.types.json;
              };

              tool = lib.mkEnableOption ''
                If enabled the extensions will be added to the tool bar.
              '';

              keepData = lib.mkEnableOption ''
                If enabled the extensions data will be saved.
              '';
            };
          });

          default = [
            {name = "darkreader";}
            {
              name = "leechblock-ng";
              keepData = true;
            }
            {name = "istilldontcareaboutcookies";}
            {
              name = "ublock-origin";
              settings = {
                adminSettings.userSettings = {
                  uiTheme = "dark";
                  uiAccentCustom = true;
                  uiAccentCustom0 = "#${self.globals.theme.palette.base0E}";
                  cloudStorageEnabled = false;
                };
              };
            }
            {
              name = "bitwarden";
              tool = true;
              keepData = true;
              settings = {
                environment = {
                  base = "https://vault.taildevourer.com";
                };
              };
            }
          ];
        };

        search = {
          engines = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                url = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                };

                alias = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                };
              };
            });

            default = {
              "NonAIGoogle" = {
                alias = "@gg";
                url = "https://www.google.com/search?udm=14&q={searchTerms}";
              };

              "Youtube" = {
                alias = "@yt";
                url = "https://www.youtube.com/results?search_query={searchTerms}";
              };

              "Nix Packages" = {
                alias = "@np";
                url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
              };

              "Nix Options" = {
                alias = "@no";
                url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
              };

              "NixOS Wiki" = {
                alias = "@nw";
                url = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
              };

              "Home Manager Options" = {
                alias = "@nh";
                url = "https://home-manager-options.extranix.com/?release=master&query={searchTerms}";
              };
            };
          };

          default = lib.mkOption {
            type = lib.types.nonEmptyStr;
            default = "NonAIGoogle";
            description = ''
              The default search engine.
            '';
          };
        };

        autoCloseTabs = lib.mkOption {
          type = lib.types.listOf lib.types.nonEmptyStr;
          default = ["*://*.darkreader.org/*"];
        };

        keepCookiesFor = lib.mkOption {
          type = lib.types.listOf lib.types.nonEmptyStr;
          default = [
            "www.youtube.com"
            "accounts.youtube.com"
            "music.youtube.com"
            "www.google.com"
            "mail.google.com"
            "github.com"
          ];
          example = ["github.com" "https://mail.google.com"];
          description = ''
            Sites whose cookies and site data are kept when the browser closes.
          '';
          apply = map (site:
            if lib.hasInfix "://" site
            then site
            else "https://" + site);
        };

        background = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Path to the background image.
          '';
          example = lib.literalExpression "./wallpaper.png";
        };
      };

      config = {
        assertions = [
          {
            assertion = lib.elem config.search.default (lib.attrNames config.search.engines);
            message = ''
              The default search engine isn't declared in the engines option. 
            '';
          }
        ];
      };
    };

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
