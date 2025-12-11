{ config, lib, pkgs, ... }:

let
  cfg = config.programs.constellation-cursor;

  configFile = ''
    cursor_scale=${toString cfg.settings.cursor_scale}
    outline_thickness=${toString cfg.settings.outline_thickness}
    fade_enabled=${lib.boolToString cfg.settings.fade_enabled}
    fade_in_enabled=${lib.boolToString cfg.settings.fade_in_enabled}
    fade_speed=${toString cfg.settings.fade_speed}
    frost_intensity=${toString cfg.settings.frost_intensity}
    hotspot_smoothing=${lib.boolToString cfg.settings.hotspot_smoothing}
    hotspot_threshold=${toString cfg.settings.hotspot_threshold}
    config_polling=${lib.boolToString cfg.settings.config_polling}
    config_poll_interval=${toString cfg.settings.config_poll_interval}
  '';
in
{
  options.programs.constellation-cursor = {
    enable = lib.mkEnableOption "Enable Constellation Cursor";

    package = lib.mkOption {
          type = lib.types.package;
          description = "The Constellation Cursor package used for LD_PRELOAD.";
        };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        cursor_scale = 1.5;
        outline_thickness = 0.0;
        fade_enabled = false;
        fade_in_enabled = false;
        fade_speed = 30;
        frost_intensity = 0;
        hotspot_smoothing = false;
        hotspot_threshold = 0;
        config_polling = true;
        config_poll_interval = 50;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/constellation_cursor/cursor.conf".text = configFile;
  };
}
