# Hardware configuration for UTM VM
# This file should be generated automatically by nixos-generate-config
# when you first install NixOS in the VM.
# For now, this is a placeholder that will work for most UTM setups.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Boot configuration
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "ahci" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # NOTE: You'll need to replace this with actual filesystem configuration
  # after running nixos-generate-config in the VM
  # For now, this is a placeholder configuration that satisfies the NixOS requirements

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # Networking (virtio is common for UTM)
  networking.useDHCP = lib.mkDefault true;

  # CPU architecture - adjust based on your VM type
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux"; # or "x86_64-linux"

  # Video driver for UTM
  services.xserver.videoDrivers = [ "virtio" ];
}