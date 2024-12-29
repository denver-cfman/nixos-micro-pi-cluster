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

}
