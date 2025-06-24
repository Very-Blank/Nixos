{config, pkgs, ...}:

{
  # System spesific.
  imports = [
    ./extra.nix
  ];

  programs.waybar =  let
    inherit (config.lib.stylix.colors)
      base00 base01 base02 base03 base04 base05 base06 base07
      base08 base09 base0A base0B base0C base0D base0E base0F;
    rawDefines = builtins.readFile ./style.css;
    processedDefines = pkgs.writeText "waybar-colors.css"
      (builtins.replaceStrings
        ["__base00__" "__base01__" "__base02__" "__base03__" "__base04__"
          "__base05__" "__base06__" "__base07__" "__base08__" "__base09__"
          "__base0A__" "__base0B__" "__base0C__" "__base0D__" "__base0E__" "__base0F__"]
        [base00 base01 base02 base03 base04
          base05 base06 base07 base08 base09
          base0A base0B base0C base0D base0E base0F]
        rawDefines);
    in {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        margin = "5 10 5 10";
        modules-center = ["clock"];

        modules-left = ["niri/workspaces" "niri/language" "keyboard-state" "custom/poweroff" "custom/hibernate" "custom/reboot"];

        "niri/language" = {
          format-en = "US";
        };

        "keyboard-state" = {
          capslock = true;
          format = "{icon}";
          format-icons = {
            locked = "";
            unlocked = "";
          };
        };

        "clock" = {
          format = "{:%a %d %b %I:%M %p}";
          tooltip = false;
        };

        "custom/poweroff" = {
          format = "";
          on-double-click = "poweroff";
          tooltip = false;
        };

        "custom/hibernate" = {
          format = "⭘";
          on-double-click = "systemctl hibernate";
          tooltip = false;
        };

        "custom/reboot" = {
          format = "";
          on-double-click = "reboot";
          tooltip = false;
        };

        "pulseaudio" = {
          reverse-scrolling = 1;
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
          min-length = 13;
        };

        "memory" = {
          interval =  30;
          format = "{}% ";
        };

        "cpu" = {
          interval = 2;
          format = "{usage}% ";
          min-length = 6;
        };

        "temperature" = {
          # thermal-zone = 2;
          # hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
          critical-threshold = 80;
          # format-critical = "{temperatureC}°C {icon}";
          format = "{temperatureC}°C {icon}";
          format-icons = ["" "" "" "" ""];
          tooltip = false;
        };

        "backlight" = {
          device = "intel_backlight";
          format = "{percent}% {icon}";
          format-icons = ["󰛩" "󱩎" "󱩏" "󱩐" "󱩑" "󱩒" "󱩓" "󱩔" "󱩕" "󱩖" "󰛨"];
          min-length = 7;
        };

        "battery" = {
          interval = 2;
          states = { warning = 30; critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% 󰂄";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
        };
      };
    };

    style = processedDefines;
  };
}
