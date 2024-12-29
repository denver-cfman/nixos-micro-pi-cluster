{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    ./sd-image.nix
    ./common-aarch64.nix
  ];

  sdImage = {
    compressImage = false;
    #imageName = "common-rpi0.img";

    extraFirmwareConfig = {
      # Give up VRAM for more Free System Memory
      # - Disable camera which automatically reserves 128MB VRAM
      start_x = 0;

      # Reduce allocation of VRAM to 16MB minimum for non-rotated
      # (32MB for rotated)
      gpu_mem = 16;

      # Configure display to 800x600 so it fits on most screens
      # * See: https://elinux.org/RPi_Configuration
      hdmi_group = 2;
      hdmi_mode = 8;
    };
  };

  # this is handled by nixos-hardware on Pi 4
  ## "console=ttyS1,115200n8" OR "console=ttyAMA0,115200n8" 
  boot = {
    kernelParams = lib.mkForce [
                                  "console=ttyS1,115200n8"
                              ];
    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
    ];
  };

  networking = { 
    wireless.enable = false;
  };


  services.zram-generator = {
    enable = true;
    settings.zram0 = {
      compression-algorithm = "zstd";
      zram-size = "ram * 2";
    };
  };

  # Disable WiFi
  hardware.enableRedistributableFirmware = lib.mkForce false;
  #hardware.firmware = [pkgs.raspberrypiWirelessFirmware];
  hardware.firmware = [ ];

}
