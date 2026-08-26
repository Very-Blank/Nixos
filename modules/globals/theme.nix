{inputs, ...}: {
  flake.globals.theme = inputs.colors.lib.theme "tokyo-night-terminal-dark";
}
