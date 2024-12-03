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
    imageName = "1b5a4d6b.img";

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
      ### usb gadget
      #dtoverlay=dwc2;
    };
  };

  # this is handled by nixos-hardware on Pi 4
  boot = {
    kernelParams = [
      "console=ttyS1,115200n8"
    ];
    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "libcomposite"
    ];
  };

  networking.hostName = "1b5a4d6b";
  #hardware.raspberry-pi."4".dwc2.enable = true;

  networking = {
    hosts = {
      "127.0.0.1" = [ "1b5a4d6b.local" ];
      "172.16.1.1" = [ "1b5a4d6b.local" ];
    };
    interfaces.usb0.ipv4.addresses = [
      {
        address = "172.16.1.1";
        prefixLength = 24;
      }
    ];
    wireless.enable = false;
  };

  networking.dhcpcd.denyInterfaces = [ "usb0" ];

/*

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      dhcp-authoritative = true;
      bind-interfaces = true;
      domain-needed = true;
      expand-hosts = true;
      bogus-priv = true;
      no-resolv = true;
      no-hosts = true;
      log-dhcp = true;
      no-poll = true;
      interface = [ "usb0" ];
      dhcp-range = [ "172.16.1.2,172.16.1.253" ];
    };
  };

*/


  systemd.services."usb-otg" = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "default.target" ];
    script = ''
      ${pkgs.kmod}/bin/modprobe libcomposite
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/1b5a4d6b
      cd /sys/kernel/config/usb_gadget/1b5a4d6b
      echo 0x1d6b > idVendor # Linux Foundation
      echo 0x0104 > idProduct # Multifunction Composite Gadget
      echo 0x0100 > bcdDevice # v1.0.0
      echo 0x0200 > bcdUSB # USB2
      echo 0xEF > bDeviceClass
      echo 0x02 > bDeviceSubClass
      echo 0x01 > bDeviceProtocol
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/1b5a4d6b/strings/0x409
      echo "fedcba9876543211" > strings/0x409/serialnumber
      echo "TheWifiNinja" > strings/0x409/manufacturer
      echo "PI4 USB Device" > strings/0x409/product
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/1b5a4d6b/configs/c.1/strings/0x409
      echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
      echo 250 > configs/c.1/MaxPower
      # Add functions here
      # see gadget configurations below
      # End functions
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/1b5a4d6b/functions/ecm.usb0
      HOST="00:dc:c8:12:7c:b3" # "HostPC"
      SELF="b8:27:eb:5a:4d:6b" # "00000000fe127cb3 / smsc95xx.macaddr=b8:27:eb:5a:4d:6b"
      echo $HOST > functions/ecm.usb0/host_addr
      echo $SELF > functions/ecm.usb0/dev_addr
      ln -s functions/ecm.usb0 configs/c.1/
      ${pkgs.systemd}/bin/udevadm settle -t 5 || :
      ls /sys/class/udc > UDC
    '';
  };
  #systemd.services.dnsmasq.after = [ "usb-otg.service" ];
  systemd.services."network-addresses-usb0".after = [ "usb-otg.service" ];
  
  

    # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # ! Be sure to change the autologinUser.
  services.getty.autologinUser = "giezac";

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    dnsmasq
    htop
    vim
    usbutils
    coreutils
    kmod
    k3s
    ethtool
  ];

}
