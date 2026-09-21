# Description: Danh sách font sáng tạo cho Studio / Livestream / Overlay
{ pkgs, ... }:

with pkgs; [
  noto-fonts-color-emoji # emoji màu (overlay/chat)
  liberation_ttf # Arial/Times/Courier metric-compatible
  fira-code # code
  roboto
  lato
  montserrat
  raleway
  oswald # chữ đậm kiểu poster/stream
  merriweather
  poppins
  source-sans-pro
  league-spartan
]
