# nixos-micro-pi-cluster
---
| ipv4 | MAC | SN | Note |
| --- | --- | --- | --- |
| 10.0.85.10 | dc:a6:32:62:18:5b | 8d4cb64d | microPi Cluster Head |
| 10.0.85.11 | 00:00:00:00:00:aa | AABBCCDD | microPi Cluster Node1 |
| 10.0.85.12 | 00:00:00:00:00:ab | AABBCCDD | microPi Cluster Node2 |
| 10.0.85.13 | 00:00:00:00:00:ac | AABBCCDD | microPi Cluster Node3 |
| 10.0.85.14 | 00:00:00:00:00:ad | AABBCCDD | microPi Cluster Node4 |
---
### check this flake
```
nix flake check -v -L --no-build github:denver-cfman/nixos-micro-pi-cluster?ref=main
```

### show this flake
```
nix flake show --all-systems --json github:denver-cfman/nixos-micro-pi-cluster?ref=main | jq '.'
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
nixos-rebuild switch --flake github:denver-cfman/nixos-micro-pi-cluster#_8d4cb64d --target-host 10.0.85.10 --use-remote-sudo
```
