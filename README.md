# nixos-micro-pi-cluster

### check this flake
```
nix flake check --no-build github:denver-cfman/nixos-micro-pi-cluster?ref=main
```

### show this flake
```
nix flake show github:denver-cfman/nixos-micro-pi-cluster?ref=main
```

### build sd image for cluster head, use ` nix flake show github:denver-cfman/nixos-micro-pi-cluster?ref=main ` to list nodes
```
nix build --rebuild -L github:denver-cfman/nixos-micro-pi-cluster?ref=main#nixosConfigurations._8d4cb64d.config.system.build.sdImage
```

### copy sd image
```
sudo cp result/sd-image/8d4cb64d.img ~/
ls ~/
```

### remote update nix (nixos-rebuild) on cluster head
```
nix run github:serokell/deploy-rs github:denver-cfman/nixos-micro-pi-cluster?ref=main#_8d4cb64d -- --ssh-user giezac --hostname 10.0.85.10
```
