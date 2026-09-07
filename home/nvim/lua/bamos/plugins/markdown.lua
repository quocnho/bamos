-- Render-markdown: render markdown đẹp trong buffer (heading/code/checkbox…).
local render_ok, render_md = pcall(require, "render-markdown")
if render_ok then
  render_md.setup {
    heading = { enabled = true, sign = true },
    code = { enabled = true, sign = true },
    checkbox = { enabled = true },
  }
end
