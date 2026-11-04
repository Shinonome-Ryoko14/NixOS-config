let
  keys = import ./keys.nix;
in
{
  # Recipients for each encrypted file, in the format ragenix expects:
  #
  #   "example.age".publicKeys = [ keys.ryoko ];
  #
  # Create or edit a secret with `ragenix -e secrets/<name>.age`.
  # The previous ciphertexts were encrypted for the original author's keys and
  # are not recoverable; recreate the values you actually need.
}
