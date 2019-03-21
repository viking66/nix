{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.opengl.driSupport32Bit = true;

  systemd.user.services.powertop = {
    enable = true;
    description = ''
      enables powertop's recommended settings on boot
    '';
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ powertop ];
    serviceConfig = {
      ExecStart = "${pkgs.powertop}/bin/powertop --auto-tune";
      Type = "oneshot";
    };
  };

  sound.enable = true;

  networking = {
    hostName = "penny";
    networkmanager.enable = true;
#    extraHosts = ''
#      172.31.98.1 https://aruba.odyssys.net/cgi-bin/login
#    '';
#    nameservers = [ "172.31.98.1" ];
  };

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "dvorak";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "America/Los_Angeles";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    xlibs.xbacklight
    cachix
    powertop
    steam
  ];

  fonts = {
    fonts = with pkgs; [
      powerline-fonts
    ];
  };

  services.xserver = {
    enable = true;
    layout = "dvorak";
    displayManager.slim = {
      enable = true;
      defaultUser = "jason";
    };
  };

  services.upower.enable = true;

  programs.ssh.askPassword = "";

  services.physlock = {
    enable = true;
    allowAnyUser = true;
  };

  users.extraUsers.jason = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "docker"
    ];
  };

  system.stateVersion = "18.09"; # Did you read the comment?
}
