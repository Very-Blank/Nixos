{
  flake = {
    # NOTE: Turns a host into a VM, fakes the hardware of `core.host.features` where possible.
    nixosModules.vm = {
      lib,
      pkgs,
      config,
      ...
    }: let
      hasFeature = feature: builtins.elem feature config.core.host.features;

      # NOTE: bluez in nixpkgs is built without the emulator, it's only needed for btvirt.
      btvirt = pkgs.bluez.overrideAttrs (old: {
        pname = "btvirt";
        configureFlags = old.configureFlags ++ ["--enable-testing"];
        postInstall =
          (old.postInstall or "")
          + ''
            install -Dm755 emulator/btvirt $out/bin/btvirt
          '';
      });

      # NOTE: There is no virtual backlight in qemu or the kernel, so this module registers one
      #       that only stores the brightness. It's a real device, so udev, logind,
      #       brightnessctl and bars all see it.
      vmBacklight = let
        inherit (config.boot.kernelPackages) kernel kernelModuleMakeFlags;

        make = target: ''
          make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M="$PWD" \
            ${lib.strings.escapeShellArgs kernelModuleMakeFlags} \
            INSTALL_MOD_PATH="$out" INSTALL_MOD_DIR=extra DEPMOD=true \
            ${target}
        '';

        source = pkgs.writeText "vm-backlight.c" ''
          #include <linux/backlight.h>
          #include <linux/module.h>
          #include <linux/platform_device.h>

          static struct platform_device *pdev;
          static struct backlight_device *bd;

          static int vm_backlight_update_status(struct backlight_device *bd)
          {
            return 0;
          }

          static const struct backlight_ops vm_backlight_ops = {
            .update_status = vm_backlight_update_status,
          };

          static int __init vm_backlight_init(void)
          {
            struct backlight_properties props = {
              .type = BACKLIGHT_RAW,
              .max_brightness = 100,
              .brightness = 100,
            };

            pdev = platform_device_register_simple("vm-backlight", -1, NULL, 0);
            if (IS_ERR(pdev))
              return PTR_ERR(pdev);

            bd = backlight_device_register("vm-backlight", &pdev->dev, NULL, &vm_backlight_ops, &props);
            if (IS_ERR(bd)) {
              platform_device_unregister(pdev);
              return PTR_ERR(bd);
            }

            return 0;
          }

          static void __exit vm_backlight_exit(void)
          {
            backlight_device_unregister(bd);
            platform_device_unregister(pdev);
          }

          module_init(vm_backlight_init);
          module_exit(vm_backlight_exit);

          MODULE_LICENSE("GPL");
          MODULE_DESCRIPTION("Fake backlight for VMs");
        '';
      in
        pkgs.stdenv.mkDerivation {
          pname = "vm-backlight";
          version = "1.0";

          dontUnpack = true;

          nativeBuildInputs = kernel.moduleBuildDependencies;

          buildPhase = ''
            cp ${source} vm-backlight.c
            echo "obj-m := vm-backlight.o" > Kbuild

            ${make "modules"}
          '';

          # NOTE: kbuild's modules_install signs the module and writes the .ko.cer
          #       certificate that NixOS's module aggregation expects.
          installPhase = make "modules_install";
        };
    in {
      core = {
        host = {
          type = "vm";
        };
      };

      hardware = {
        graphics = {
          enable = true;
        };
      };

      virtualisation = {
        vmVariant = {
          virtualisation = {
            memorySize = 4096;
            cores = 4;
            qemu = {
              options =
                [
                  "-device virtio-vga-gl"
                  "-display gtk,gl=on"
                ]
                # Real sound card, played through the host's pipewire.
                ++ lib.optionals (hasFeature "audio") [
                  "-audiodev pipewire,id=audio0"
                  "-device intel-hda"
                  "-device hda-duplex,audiodev=audio0"
                ];
            };
          };

          boot = {
            kernelModules =
              # Fake battery and AC adapter, values can be changed at runtime in
              # /sys/module/test_power/parameters/.
              lib.optionals (hasFeature "battery") ["test_power"]
              # Fake wifi card.
              ++ lib.optionals (hasFeature "wifi") ["mac80211_hwsim"]
              # Virtual bluetooth controllers, emulated by btvirt.
              ++ lib.optionals (hasFeature "bluetooth") ["hci_vhci"]
              # Fake backlight at /sys/class/backlight/vm-backlight.
              ++ lib.optionals (hasFeature "brightness") ["vm-backlight"];

            extraModulePackages = lib.optionals (hasFeature "brightness") [vmBacklight];

            extraModprobeConfig = lib.mkIf (hasFeature "wifi") ''
              options mac80211_hwsim radios=1
            '';
          };

          systemd = {
            services = {
              btvirt = lib.mkIf (hasFeature "bluetooth") {
                description = "Emulated bluetooth controller";
                # NOTE: bluetooth.service is only started once a controller shows up,
                #       so this can't be pulled in by it.
                wantedBy = ["multi-user.target"];
                before = ["bluetooth.service"];

                serviceConfig = {
                  ExecStart = "${lib.getExe' btvirt "btvirt"} -l1";
                };
              };
            };
          };
        };
      };
    };
  };
}
