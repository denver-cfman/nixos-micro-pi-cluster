# nixos-micro-pi-cluster

### check this flake
```
nix flake check --no-build github:denver-cfman/nixos-micro-pi-cluster?ref=main
```

### show this flake
```
nix flake show github:denver-cfman/nixos-micro-pi-cluster?ref=main
```

### build sd image for cluster head
```
git clone https://github.com/denver-cfman/nixos-micro-pi-cluster
cd nixos-micro-pi-cluster
nix build -L .#nixosConfigurations._8d4cb64d.config.system.build.sdImage
```

### copy sd image
```
cp result/sd-images/8d4cb64d.img ~/
ls ~/
```
