# Description: Plugins tự build ngoài nixpkgs
{ pkgs, ... }:

{
  my-note-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "my-note-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "jellydn";
      repo = "my-note.nvim";
      rev = "bce15c38514df229eb446a6b6bef2fcbb1993e80";
      sha256 = "1dl57hq833aaaxgc4iyn0b77zgrxmhidzj9xdgylnrhah3k7qdx5";
    };
  };

  tiny-term-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "tiny-term-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "jellydn";
      repo = "tiny-term.nvim";
      rev = "51224ee32fe0e88be1d5dd21afa8874ee7568180";
      sha256 = "0j0qn9q9dzzjihk4fg9wkzbrxrjjwx3925h0rxldd1j5f7q95py0";
    };
  };
}
