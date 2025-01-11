{
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  pi-sn = "004f17e5";
  host-mac = "00:dc:00:4f:17:e5";
  usb-mac = "00:00:00:4f:17:e5";
  k3sToken = builtins.getEnv "K3S_TOKEN" or "somereallylongfakevaluegoeshere"; # Replaceable variable
in
{
  imports = [
    ./sd-image.nix
    ./common-aarch64.nix
    ./common-rpi0-node.nix
  ];

  sdImage.imageName  = lib.mkForce "${pi-sn}.img";
  networking.hostName = lib.mkForce "${pi-sn}";


  networking = {
    hostName = lib.mkForce "${pi-sn}";
    extraHosts = lib.mkForce ''
10.0.85.10 clusterhat clusterhat.micro.giezenconsulting.com
'';
  };

  services.k3s = {
    enable = true;
    token = "K109225314c2362ddcf00d33e670e2cb09150ca11226f469c52c89d1b7ee4bd3a9c::server:mytoken";
    role = "agent";
    serverAddr="https://rpi4-cluster-head.giezenconsulting.com:6443";
    extraFlags = "--disable=servicelb";
    #disableAgent = "false";
  };

  systemd.services."usb-otg" = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "default.target" ];
    script = ''
      ${pkgs.kmod}/bin/modprobe libcomposite
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/${pi-sn}
      cd /sys/kernel/config/usb_gadget/${pi-sn}
      echo 0x1d6b > idVendor # Linux Foundation
      echo 0x0104 > idProduct # Multifunction Composite Gadget
      echo 0x0100 > bcdDevice # v1.0.0
      echo 0x0200 > bcdUSB # USB2
      echo 0xEF > bDeviceClass
      echo 0x02 > bDeviceSubClass
      echo 0x01 > bDeviceProtocol
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/${pi-sn}/strings/0x409
      echo "${pi-sn}" > strings/0x409/serialnumber
      echo "GiezenConsulting" > strings/0x409/manufacturer
      echo "micro-pi-cluster-node" > strings/0x409/product
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/${pi-sn}/configs/c.1/strings/0x409
      echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
      echo 250 > configs/c.1/MaxPower
      # Add functions here
      # see gadget configurations below
      # End functions
      ${pkgs.coreutils}/bin/mkdir -p /sys/kernel/config/usb_gadget/${pi-sn}/functions/ecm.usb0
      HOST="${host-mac}"
      SELF="${usb-mac}"
      echo $HOST > functions/ecm.usb0/host_addr
      echo $SELF > functions/ecm.usb0/dev_addr
      ln -s functions/ecm.usb0 configs/c.1/
      ${pkgs.systemd}/bin/udevadm settle -t 5 || :
      ls /sys/class/udc > UDC
    '';
  };

}
