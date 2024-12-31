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
    ./common-rpi0-node.nix
  ];

  sdImage.imageName  = lib.mkForce "004f17e5.img";
  networking.hostName = lib.mkForce "004f17e5";

  
  systemd.services."usb-otg" = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "default.target" ];
    script = ''
      ${pkgs.kmod}/bin/modprobe libcomposite
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/004f17e5
      cd /sys/kernel/config/usb_gadget/004f17e5
      echo 0x1d6b > idVendor # Linux Foundation
      echo 0x0104 > idProduct # Multifunction Composite Gadget
      echo 0x0100 > bcdDevice # v1.0.0
      echo 0x0200 > bcdUSB # USB2
      echo 0xEF > bDeviceClass
      echo 0x02 > bDeviceSubClass
      echo 0x01 > bDeviceProtocol
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/004f17e5/strings/0x409
      echo "fedcba004f17e5" > strings/0x409/serialnumber
      echo "TheWifiNinja" > strings/0x409/manufacturer
      echo "PI4 USB Device" > strings/0x409/product
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/004f17e5/configs/c.1/strings/0x409
      echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
      echo 250 > configs/c.1/MaxPower
      # Add functions here
      # see gadget configurations below
      # End functions
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/004f17e5/functions/ecm.usb0
      HOST="00:dc:c8:12:7c:b3" # "HostPC"
      SELF="00:00:00:00:00:a1" # "00000000fe127cb3 / smsc95xx.macaddr=b8:27:eb:5a:4d:6b"
      echo $HOST > functions/ecm.usb0/host_addr
      echo $SELF > functions/ecm.usb0/dev_addr
      ln -s functions/ecm.usb0 configs/c.1/
      ${pkgs.systemd}/bin/udevadm settle -t 5 || :
      ls /sys/class/udc > UDC
    '';
  };
  #systemd.services.dnsmasq.after = [ "usb-otg.service" ];
  systemd.services."network-addresses-usb0".after = [ "usb-otg.service" ];
  

}
