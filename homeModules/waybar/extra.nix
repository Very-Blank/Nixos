{ ... }: 

{
  programs.waybar = {
    settings = {
      mainBar = {
        modules-right = ["pulseaudio" "memory" "cpu" "backlight" "battery"];
      };
    };
  };
}
