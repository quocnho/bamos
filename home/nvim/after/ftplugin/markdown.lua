-- Markdown (port after/ftplugin/markdown.lua của jdhao — lệnh :AddRef).
-- :AddRef <label> <url> → thêm reference link vào cuối file + mục References.
local function add_reference_at_end(label, url)
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local has_ref_section = false
    for _, line in ipairs(lines) do
      if line:match("^%s*<!%-%-.*[Rr]eferences.*%-%->[%s]*$") then
        has_ref_section = true
        break
      end
    end

    local to_add = {}
    if not has_ref_section then
      table.insert(to_add, "")
      table.insert(to_add, "<!-- References -->")
    end
    table.insert(to_add, string.format("[%s]: %s", label, url))
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, to_add)
  end)
end

vim.api.nvim_buf_create_user_command(0, "AddRef", function(opts)
  local args = vim.split(opts.args, " ", { trimempty = true })
  if #args < 2 then
    vim.print("Usage: :AddRef <label> <url>")
    return
  end
  add_reference_at_end(args[1], args[2])
end, { desc = "Add reference link at buffer end", nargs = "+" })
