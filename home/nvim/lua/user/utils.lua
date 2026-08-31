-- Tiện ích dùng chung (port từ lua/utils.lua của jdhao/nvim-config).
local fn = vim.fn

local M = {}

--- Kiểm tra executable tồn tại trong PATH (quan trọng cho LSP/devenv)
--- @param name string
--- @return boolean
function M.executable(name)
  return fn.executable(name) > 0
end

--- Kiểm tra feature của Nvim, vd "nvim-0.11", "unix"
function M.has(feat)
  return fn.has(feat) == 1
end

--- Tạo thư mục nếu chưa tồn tại
function M.may_create_dir(dir)
  if fn.isdirectory(dir) == 0 then
    fn.mkdir(dir, "p")
  end
end

--- Tìm root của dự án hiện tại
--- @return string | nil
function M.get_proj_root()
  return vim.fs.root(0, { ".git", "pyproject.toml", "flake.nix", "devenv.nix" })
end

--- Tên môi trường ảo đang kích hoạt (VIRTUAL_ENV / CONDA_DEFAULT_ENV)
function M.get_virtual_env()
  local venv_path = os.getenv("VIRTUAL_ENV")
  local conda_env = os.getenv("CONDA_DEFAULT_ENV")
  if venv_path then
    return vim.fn.fnamemodify(venv_path, ":t")
  end
  return conda_env or ""
end

--- Loại môi trường Python của project: "plain_venv" | "uv" | ""
function M.get_py_env()
  local root = M.get_proj_root()
  if root == nil then
    return ""
  end
  if M.get_virtual_env() ~= "" then
    return "plain_venv"
  end
  if vim.uv.fs_stat(vim.fs.joinpath(root, "uv.lock")) then
    return "uv"
  end
  return ""
end

--- Chuỗi tiêu đề cửa sổ: hostname + path + thời gian sửa cuối
function M.get_titlestr()
  local title_str = ""
  if vim.g.is_linux then
    title_str = vim.fn.hostname() .. "  "
  end
  local buf_path = vim.fn.expand("%:p:~")
  title_str = title_str .. buf_path .. "  "
  if vim.bo.buflisted and buf_path ~= "" then
    title_str = title_str .. vim.fn.strftime("%Y-%m-%d %H:%M:%S%z", vim.fn.getftime(vim.fn.expand("%")))
  end
  return title_str
end

return M
