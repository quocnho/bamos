-- Editor options (chuẩn 2-space, tinh chỉnh cho editor hiện đại trên nvim 0.12).
local utils = require("bamos.utils")
local fn = vim.fn
local opt = vim.opt
local o = vim.o

-- Fillchars: folding, split, eob…
opt.fillchars = {
  fold = " ",
  foldsep = " ",
  foldopen = "",
  foldclose = "",
  vert = "│",
  eob = " ",
  msgsep = "‾",
  diff = "╱",
}

opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

opt.timeoutlen = 500
opt.updatetime = 500 -- cho CursorHold

-- Clipboard: dùng chung hệ thống (nếu có provider)
if fn["provider#clipboard#Executable"]() ~= "" then
  opt.clipboard:append("unnamedplus")
end

opt.swapfile = false -- không tạo swapfile

opt.wildignore:append {
  "*.o", "*.obj", "*.dylib", "*.bin", "*.dll", "*.exe",
  "*/.git/*", "*/.svn/*", "*/__pycache__/*", "*/build/**", "*/node_modules/**",
  "*.jpg", "*.png", "*.jpeg", "*.bmp", "*.gif", "*.tiff", "*.svg", "*.ico",
  "*.pyc", "*.pkl", "*.DS_Store",
  "*.aux", "*.bbl", "*.blg", "*.brf", "*.fls", "*.fdb_latexmk", "*.synctex.gz", "*.xdv",
}
opt.wildignorecase = true

-- Backup vào thư mục riêng (không rác cạnh file)
vim.g.backupdir = fn.stdpath("data") .. "/backup//"
opt.backupdir = vim.g.backupdir
opt.backup = true
opt.backupcopy = "yes"

-- Tab: 2 spaces
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.shiftround = true

-- matchpairs: KHÔNG thêm `"<:>"` (đã có sẵn mặc định — nvim ≥0.12 báo E474 nếu
-- thêm trùng) và không thêm nháy đơn/kép (vim cấm). Chỉ thêm cặp CJK:
opt.matchpairs:append("「:」,『:』,【:】,《:》")

opt.number = true
opt.relativenumber = true

opt.ignorecase = true
opt.smartcase = true

opt.fileencoding = "utf-8"
opt.fileencodings = { "ucs-bom", "utf-8", "cp936", "gb18030", "big5", "euc-jp", "euc-kr", "latin1" }

opt.linebreak = true
opt.showbreak = "↪"
opt.wildmode = "list:longest"
opt.scrolloff = 5
opt.sidescroll = 1
opt.sidescrolloff = 8

opt.mouse = "n"
opt.mousemodel = "popup"
opt.mousescroll = { "ver:1", "hor:0" }

opt.showmode = false -- statusline đã hiện mode
opt.fileformats = { "unix", "dos" }
opt.confirm = true
opt.visualbell = true
opt.errorbells = false
opt.history = 500

opt.list = true
opt.listchars = { tab = "▸ ", extends = "❯", precedes = "❮", nbsp = "␣" }

opt.autowrite = true
opt.autowriteall = true
opt.autoread = true

-- Tiêu đề cửa sổ: hostname + path + thời gian sửa
opt.title = true
o.titlestring = "%{v:lua.require('bamos.utils').get_titlestr()}"

opt.undofile = true -- undo bền vững qua các lần mở

opt.shortmess:append("cS")
opt.messagesopt = "hit-enter,history:500"

-- Completion: không preview window, menu nhỏ gọn
opt.completeopt:append("menuone")
opt.completeopt:remove("preview")
opt.pumheight = 10
opt.pumblend = 5
opt.pumborder = "single"
opt.winblend = 0
opt.winborder = "single"
opt.complete:append("kspell")
opt.complete:remove { "w", "b", "u", "t" }

opt.spelllang = { "en", "cjk" } -- hỗ trợ gõ tiếng Việt/Unicode
opt.spellsuggest:append("9")

opt.virtualedit = "block"
opt.formatoptions:append("mM") -- ngắt dòng đúng ký tự CJK
opt.tildeop = true
opt.synmaxcol = 250
opt.startofline = false

-- Grep: ưu tiên ripgrep (có sẵn trên NixOS qua home.packages)
if utils.executable("rg") then
  opt.grepprg = "rg --vimgrep --no-heading --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
end

opt.termguicolors = true -- true color
opt.guicursor = "n-v:block-Cursor/lCursor,i-c-ci-ve:ver50-blinkwait50-blinkoff100-blinkon175-Cursor2/lCursor2,r-cr:hor20,o:hor20"

opt.signcolumn = "yes:1"
opt.colorcolumn = "100"

opt.isfname:remove { "=", "," }

-- Diff: dọc, inline char cho dễ nhìn thay đổi trong dòng
opt.diffopt = {
  "vertical", "filler", "closeoff", "context:3",
  "internal", "indent-heuristic", "algorithm:histogram",
}
opt.diffopt:append("inline:char")

opt.wrap = false
opt.ruler = false
opt.showcmdloc = "statusline"
