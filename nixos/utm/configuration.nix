{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "utm";
  networking.networkmanager.enable = true;

  # Time zone and localization
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable QEMU guest support for UTM
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # X11/Wayland - minimal desktop (you can change this based on preference)
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define your user account
  users.users.zupo = {
    isNormalUser = true;
    description = "Neyts Zupan";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGrPamqqGqV9sf/hhyt/aSF0Osdqf/vjz++60j+p208vweE4KSHLvncxlFHLdzMdOUMsYO7bStxDoAenJ9nirQY= zupo@secretive.zbook.local"
    ];
  };

  # Enable zsh globally since we're using it as the shell
  programs.zsh.enable = true;

  # Enable automatic login for convenience in VM
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "zupo";

  # Workaround for GNOME autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Enable SSH daemon
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";
  services.openssh.settings.PasswordAuthentication = false;

  # Enable Nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
  ];

  # Firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ]; # SSH

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.05";
}
