{ lib, pkgs ? null }:

{
  display-helpers = import ./display-helpers.nix { inherit lib pkgs; };
  edid = import ./edid.nix { inherit lib; };
}
