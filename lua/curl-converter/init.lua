local config = require("curl-converter.config")
local installer = require("curl-converter.installer")
local ui = require("curl-converter.ui")

local M = {}

function M.setup(opts)
  config.setup(opts)

  if config.options.auto_install_deps then
    installer.ensure_installed()
  end

  vim.api.nvim_create_user_command("CurlConvert", function()
    ui.start()
  end, {
    desc = "Convert curl command to code (opens input buffer)",
  })

  vim.api.nvim_create_user_command("CurlConvertPaste", function()
    ui.start_from_clipboard()
  end, {
    desc = "Convert curl from clipboard directly",
  })

  vim.api.nvim_create_user_command("CurlConvertInstall", function()
    installer.install()
  end, {
    desc = "Install curlconverter npm dependency",
  })
end

function M.convert(curl_cmd, language)
  local converter = require("curl-converter.converter")
  return converter.convert(curl_cmd, language)
end

return M
