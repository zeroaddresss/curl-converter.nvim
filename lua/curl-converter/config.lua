local M = {}

M.defaults = {
  node_path = "node",
  auto_install_deps = true,
  output_window = {
    border = "rounded",
    width = 0.8,
    height = 0.8,
  },
  keymaps = {
    close = "q",
    yank = "y",
    reselect = "r",
  },
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

M.setup()

return M
