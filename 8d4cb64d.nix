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


  services.udev.extraRules = lib.mkForce ''
    KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys/class/gpio && ${pkgs.coreutils}/bin/chmod -R g=u /sys/class/gpio'"
    SUBSYSTEM=="gpio", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys%p && ${pkgs.coreutils}/bin/chmod -R g=u /sys%p'"
    ACTION=="add", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{manufacturer}=="GiezenConsulting", ATTRS{serial}=="1b5a4d6b", NAME="node1"
    ACTION=="remove", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{manufacturer}=="GiezenConsulting", ATTRS{serial}=="1b5a4d6b", NAME="node1", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.nettools}/bin/ifconfig node1 down || true && ${pkgs.bridge-utils}/bin/brctl delif br0 node1 || true'"
    ACTION=="add", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{manufacturer}=="GiezenConsulting", ATTRS{serial}=="fe127cb3", NAME="node2"
    ACTION=="remove", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{manufacturer}=="GiezenConsulting", ATTRS{serial}=="fe127cb3", NAME="node2", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.nettools}/bin/ifconfig node2 down || true && ${pkgs.bridge-utils}/bin/brctl delif br0 node2 || true'"
    ACTION=="add", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{manufacturer}=="GiezenConsulting", ATTRS{serial}=="04a91ec3", NAME="node3"
    ACTION=="remove", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{manufacturer}=="GiezenConsulting", ATTRS{serial}=="04a91ec3", NAME="node3", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.nettools}/bin/ifconfig node3 down || true && ${pkgs.bridge-utils}/bin/brctl delif br0 node3 || true'"
    ACTION=="add", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{manufacturer}=="GiezenConsulting", ATTRS{serial}=="004f17e5", NAME="node4"
    ACTION=="remove", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{manufacturer}=="GiezenConsulting", ATTRS{serial}=="004f17e5", NAME="node4", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.nettools}/bin/ifconfig node4 down || true && ${pkgs.bridge-utils}/bin/brctl delif br0 node4 || true'"
  '';


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

  networking.useDHCP = lib.mkForce false;

  networking.bridges = {
    "br0" = {
      rstp = false;
      interfaces = [ 
                      "eth0"
      ];
    };
  };

  networking.interfaces.br0.ipv4.addresses = [ {
    address = "10.0.85.10";
    prefixLength = 24;
  } ];

  networking.defaultGateway = {
    address = "10.0.85.1";
    interface = "br0";
  };

  networking.nameservers = [
    "10.0.85.1"
    "8.8.8.8"
    "1.1.1.1"
  ];

  systemd.services."cluster-hat" = {
    description = "MicroPi ClusterHat Prep Script";
    enable = true;
    reloadIfChanged = false;
    restartIfChanged = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ 
                  "default.target"
                  "cluster-node1.service"
                  "cluster-node2.service"
                  "cluster-node3.service"
                  "cluster-node4.service"
                ];
    reload = ''
    '';
    script = ''
      ${pkgs.nettools}/bin/ifconfig node4 down|| true
      ${pkgs.nettools}/bin/ifconfig node3 down || true
      ${pkgs.nettools}/bin/ifconfig node2 down || true
      ${pkgs.nettools}/bin/ifconfig node1 down || true
      ${pkgs.bridge-utils}/bin/brctl delif br0 node4 || true
      ${pkgs.bridge-utils}/bin/brctl delif br0 node3 || true
      ${pkgs.bridge-utils}/bin/brctl delif br0 node2 || true
      ${pkgs.bridge-utils}/bin/brctl delif br0 node1 || true
      # POR has been cut so turn on P1-P4
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#000001111)) 1 0x20 1 0xff
      # Turn off the ALERT LED
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#01000000)) 1 0x20 1 0x00
      ${pkgs.i2c-tools}/bin/i2cset -y 1 0x20 3 0x00
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00100000)) 1 0x20 1 0x00
      ###
      # Version >2.0 turn HUB off (set bit 5 to 1)
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00100000)) 1 0x20 1 0xff
      # Version >2.0 turn HUB on (set bit 5 to 0)
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00100000)) 1 0x20 1 0x00
    '';
  };

  systemd.services."cluster-node1" = {
    description = "MicroPi Cluster Turn On Node 1";
    enable = true;
    reloadIfChanged = false;
    restartIfChanged = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "default.target" ];
    after = [
              "cluster-hat.service"
              "off-all-cluster-nodes.service"
            ];
    reload = ''
    '';
    script = ''
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00000001)) 1 0x20 1 0xff # Node 1
      ${pkgs.coreutils}/bin/sleep 45
      ${pkgs.bridge-utils}/bin/brctl addif br0 node1 || true
      ${pkgs.nettools}/bin/ifconfig node1 up || true
    '';
    preStop = ''
      ${pkgs.nettools}/bin/ifconfig node1 down
      ${pkgs.bridge-utils}/bin/brctl delif br0 node1 || true
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00000001)) 1 0x20 1 0x00 # Node 1
    '';
  };

  systemd.services."cluster-node2" = {
    description = "MicroPi Cluster Turn On Node 2";
    enable = true;
    reloadIfChanged = false;
    restartIfChanged = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "default.target" ];
    after = [
              "cluster-hat.service"
            ];
    reload = ''
    '';
    script = ''
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00000010)) 1 0x20 1 0xff # Node 2
      ${pkgs.coreutils}/bin/sleep 45
      ${pkgs.bridge-utils}/bin/brctl addif br0 node2 || true
      ${pkgs.nettools}/bin/ifconfig node2 up || true
    '';
    preStop = ''
      ${pkgs.nettools}/bin/ifconfig node2 down
      ${pkgs.bridge-utils}/bin/brctl delif br0 node2 || true
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00000010)) 1 0x20 1 0x00 # Node 2
    '';
  };

  systemd.services."cluster-node3" = {
    description = "MicroPi Cluster Turn On Node 3";
    enable = true;
    reloadIfChanged = false;
    restartIfChanged = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "default.target" ];
    after = [
              "cluster-hat.service"
            ];
    reload = ''
    '';
    script = ''
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00000100)) 1 0x20 1 0xff # Node 3
      ${pkgs.coreutils}/bin/sleep 45
      ${pkgs.bridge-utils}/bin/brctl addif br0 node3 || true
      ${pkgs.nettools}/bin/ifconfig node3 up || true
    '';
    preStop = ''
      ${pkgs.nettools}/bin/ifconfig node3 down
      ${pkgs.bridge-utils}/bin/brctl delif br0 node3 || true
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00000100)) 1 0x20 1 0x00 # Node 3
    '';
  };

  systemd.services."cluster-node4" = {
    description = "MicroPi Cluster Turn On Node 4";
    enable = true;
    reloadIfChanged = false;
    restartIfChanged = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "default.target" ];
    after = [
              "cluster-hat.service"
            ];
    reload = ''
    '';
    script = ''
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00001000)) 1 0x20 1 0xff # Node 4
      ${pkgs.coreutils}/bin/sleep 45
      ${pkgs.bridge-utils}/bin/brctl addif br0 node4 || true
      ${pkgs.nettools}/bin/ifconfig node4 up || true
    '';
    preStop = ''
      ${pkgs.nettools}/bin/ifconfig node4 down
      ${pkgs.bridge-utils}/bin/brctl delif br0 node4 || true
      ${pkgs.i2c-tools}/bin/i2cset -y -m $((2#00001000)) 1 0x20 1 0x00 # Node 4
    '';
  };

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
    #neovim
    htop
    btop
    #btop-rocm
    usbtop
    iftop
    iotop
    sysdig
    s-tui
    #dnsmasq
    htop
    jq
    vim
    usbutils
    coreutils
    ethtool
    i2c-tools
    bridge-utils
  ];

}
