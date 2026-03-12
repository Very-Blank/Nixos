{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    modules = {
      graphical = {
        applications = {
          browsers = {
            firefox = {
              enable = lib.mkEnableOption "Enable the firefox module.";
            };
          };
        };
      };
    };
  };

  # browser.toolbarbuttons.introduced.sidebar-button
  # browser.engagement.sidebar-button.has-used

  config = let
    cfg = config.modules.graphical.applications.browsers.firefox;
  in
    lib.mkIf cfg.enable {
      fonts = {
        packages = [
          pkgs.noto-fonts
          pkgs.noto-fonts-color-emoji
        ];
      };

      userHome = {
        programs.firefox = {
          enable = true;
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
            HardwareAcceleration = false;
            OfferToSaveLogins = false;
            # DefaultDownloadDirectory = "${home}/Downloads";

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

            ExtensionSettings = let
              moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
            in {
              "*".installation_mode = "blocked";

              "floccus@handmadeideas.org" = {
                install_url = moz "floccus";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

              "uBlock0@raymondhill.net" = {
                install_url = moz "ublock-origin";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

              "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                install_url = moz "bitwarden-password-manager";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

              "{22b0eca1-8c02-4c0d-a5d7-6604ddd9836e}" = {
                install_url = moz "nicothin-space";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

              "{73a6fe31-595d-460b-a920-fcc0f8843232}" = {
                install_url = moz "noscript";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

              "leechblockng@proginosko.com" = {
                install_url = moz "leechblock-ng";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

              "addon@darkreader.org" = {
                install_url = moz "darkreader";
                installation_mode = "force_installed";
                updates_disabled = true;
              };
            };

            "3rdparty".Extensions = {
              "uBlock0@raymondhill.net".adminSettings = {
                userSettings = {
                  uiTheme = "dark";
                  uiAccentCustom = true;
                  uiAccentCustom0 = "#${config.colors.palette.base00}";
                  cloudStorageEnabled = lib.mkForce false;
                };
              };
            };

            Preferences = let
              lock-false = {
                Value = false;
                Status = "locked";
              };
              lock-true = {
                Value = true;
                Status = "locked";
              };
            in {
              "browser.contentblocking.category" = {
                Value = "strict";
                Status = "locked";
              };

              "extensions.pocket.enabled" = lock-false;
              "extensions.screenshots.disabled" = lock-true;

              "browser.topsites.contile.enabled" = lock-false;
              "browser.formfill.enable" = lock-false;

              "browser.search.suggest.enabled" = lock-false;
              "browser.search.suggest.enabled.private" = lock-false;

              "browser.urlbar.suggest.searches" = lock-false;
              "browser.urlbar.showSearchSuggestionsFirst" = lock-false;

              "browser.urlbar.update2.engineAliasRefresh" = lock-true;

              "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
              "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
              "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
              "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
              "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
              "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
              "browser.newtabpage.activity-stream.showSponsored" = lock-false;
              "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;

              "browser.toolbars.bookmarks.visibility" = {
                Value = "never";
                Locked = "locked";
              };
            };
          };

          profiles = {
            default = {
              settings = {
                "middlemouse.paste" = false;
                "sidebar.revamp" = true;
                "sidebar.verticalTabs" = true;
                "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;
                "sidebar.main.tools" = "bookmarks,{446900e4-71c2-419f-a6a7-df9c091e268b}";
                "browser.newtabpage.pinned" = [
                  {
                    title = "Ouroboros";
                    url = "https://taildevourer.com/";
                  }
                  {
                    title = "Ouroboros";
                    url = "https://cloud.taildevourer.com/";
                  }
                ];

                "browser.uiCustomization.state" = {
                  placements = {
                    widget-overflow-fixed-list = [];

                    unified-extensions-area = [
                      "leechblockng_proginosko_com-browser-action"
                      "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                    ];

                    nav-bar = [
                      "back-button"
                      "forward-button"
                      "stop-reload-button"
                      "sidebar-button"
                      "privatebrowsing-button"
                      "customizableui-special-spring1"
                      "urlbar-container"
                      "customizableui-special-spring2"
                      "downloads-button"
                      "vertical-spacer"
                      "_73a6fe31-595d-460b-a920-fcc0f8843232_-browser-action"
                      "ublock0_raymondhill_net-browser-action"
                      "unified-extensions-button"
                    ];

                    toolbar-menubar = [
                      "menubar-items"
                    ];

                    TabsToolbar = [];

                    vertical-tabs = [
                      "tabbrowser-tabs"
                    ];

                    PersonalToolbar = [
                      "personal-bookmarks"
                    ];
                  };

                  seen = [
                    "addon_darkreader_org-browser-action"
                    "leechblockng_proginosko_com-browser-action"
                    "ublock0_raymondhill_net-browser-action"
                    "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                    "_73a6fe31-595d-460b-a920-fcc0f8843232_-browser-action"
                    "developer-button"
                  ];

                  dirtyAreaCache = [
                    "unified-extensions-area"
                    "nav-bar"
                    "toolbar-menubar"
                    "TabsToolbar"
                    "vertical-tabs"
                    "PersonalToolbar"
                  ];

                  currentVersion = 23;
                  newElementCount = 2;
                };
              };

              search = {
                force = true;
                default = "NonAIGoogle";
                privateDefault = "NonAIGoogle";

                engines = {
                  "NonAIGoogle" = {
                    urls = [
                      {
                        template = "https://www.google.com/search?";
                        params = [
                          {
                            name = "udm";
                            value = "14";
                          }
                          {
                            name = "q";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                    definedAliases = ["@gg"];
                  };

                  "Youtube" = {
                    urls = [
                      {
                        template = "https://www.youtube.com/results?";
                        params = [
                          {
                            name = "search_query";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                    definedAliases = ["@yt"];
                  };

                  "Claude" = {
                    urls = [
                      {
                        template = "https://claude.ai/new";
                        params = [
                          {
                            name = "q";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                    definedAliases = ["@cl"];
                  };

                  "Nix Packages" = {
                    urls = [
                      {
                        template = "https://search.nixos.org/packages";
                        params = [
                          {
                            name = "channel";
                            value = "unstable";
                          }
                          {
                            name = "query";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                    definedAliases = ["@np"];
                  };

                  "Nix Options" = {
                    urls = [
                      {
                        template = "https://search.nixos.org/options";
                        params = [
                          {
                            name = "channel";
                            value = "unstable";
                          }
                          {
                            name = "query";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                    definedAliases = ["@no"];
                  };

                  "NixOS Wiki" = {
                    urls = [
                      {
                        template = "https://wiki.nixos.org/w/index.php";
                        params = [
                          {
                            name = "search";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                    definedAliases = ["@nw"];
                  };

                  "Home Manager Options" = {
                    urls = [
                      {
                        template = "https://home-manager-options.extranix.com/";
                        params = [
                          {
                            name = "release";
                            value = "master";
                          }
                          {
                            name = "query";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                    definedAliases = ["@nh"];
                  };
                };
              };
            };
          };
        };
      };
    };
}
