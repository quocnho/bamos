-- Statuscol: cột số dòng + sign gọn, click được (như IDE).
require("statuscol").setup {
  segments = {
    { text = { "%s" }, click = "v:lua.ScFa" },
    { text = { "%C" }, click = "v:lua.ScSa" },
    { text = { " ", "%l", " " }, click = "v:lua.ScLn" },
    { text = { " ", "%c", " " }, click = "v:lua.ScCo" },
  },
  relculright = true,
}
