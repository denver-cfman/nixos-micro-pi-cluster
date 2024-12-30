{
  lib,
  modulesPath,
  pkgs,
  nixos-hardware,
  ...
}:
{
  imports = [
    ./sd-image.nix
    ./common-aarch64.nix
    "${nixos-hardware}/raspberry-pi/4"
  ];

  sdImage = {
    compressImage = false;
    imageName = "8d4cb64d.img";

    extraFirmwareConfig = {
      # Give up VRAM for more Free System Memory
      # - Disable camera which automatically reserves 128MB VRAM
      start_x = 0;

      # Configure display to 800x600 so it fits on most screens
      # * See: https://elinux.org/RPi_Configuration
      hdmi_group = 2;
      hdmi_mode = 8;
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


  networking.hostName = "clusterhat";

  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      fkms-3d.enable = true; # rudolf
      i2c1.enable = true;
      # dwc2.enable = true;
    };
    deviceTree = {
      enable = true;
    };
  };

  networking = {
    hosts = {
      "127.0.0.1" = [ "clusterhat.local" ];
      #"172.16.1.1" = [ "clusterhat.local" ];
    };
    #interfaces.usb0.ipv4.addresses = [
    #  {
    #    address = "172.16.1.1";
    #    prefixLength = 24;
    #  }
    #];
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
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/8d4cb64d
      cd /sys/kernel/config/usb_gadget/8d4cb64d
      echo 0x1d6b > idVendor # Linux Foundation
      echo 0x0104 > idProduct # Multifunction Composite Gadget
      echo 0x0100 > bcdDevice # v1.0.0
      echo 0x0200 > bcdUSB # USB2
      echo 0xEF > bDeviceClass
      echo 0x02 > bDeviceSubClass
      echo 0x01 > bDeviceProtocol
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/8d4cb64d/strings/0x409
      echo "fedcba8d4cb64d" > strings/0x409/serialnumber
      echo "TheWifiNinja" > strings/0x409/manufacturer
      echo "PI4 USB Device" > strings/0x409/product
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/8d4cb64d/configs/c.1/strings/0x409
      echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
      echo 250 > configs/c.1/MaxPower
      # Add functions here
      # see gadget configurations below
      # End functions
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/8d4cb64d/functions/ecm.usb0
      HOST="00:dc:c8:12:7c:b3"
      SELF="b8:27:eb:12:7c:b2"
      echo $HOST > /sys/kernel/config/usb_gadget/8d4cb64d/functions/ecm.usb0/host_addr
      echo $SELF > /sys/kernel/config/usb_gadget/8d4cb64d/functions/ecm.usb0/dev_addr
      ln -s /sys/kernel/config/usb_gadget/8d4cb64d/functions/ecm.usb0 configs/c.1/
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
    #dnsmasq
    htop
    jq
    vim
    usbutils
    coreutils
    ethtool
    i2c-tools
  ];

}
