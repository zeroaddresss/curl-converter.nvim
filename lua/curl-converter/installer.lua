local config = require("curl-converter.config")

local M = {}

local installing = false
local install_callbacks = {}

function M.node_dir()
  return vim.fn.stdpath("data") .. "/site/curl-converter-nvim/node"
end

function M.is_installed()
  local dir = M.node_dir()
  return vim.fn.isdirectory(dir .. "/node_modules/curlconverter") == 1
end

function M.is_installing()
  return installing
end

function M.on_install_complete(callback)
  if not installing then
    pcall(callback, M.is_installed())
    return
  end
  table.insert(install_callbacks, callback)
end

local function find_convert_mjs()
  local info = debug.getinfo(2, "S")
  if info and info.source then
    local src_path = info.source:match("@?(.*)")
    if src_path then
      local resolved = vim.fn.fnamemodify(src_path, ":p:h:h:h") .. "/node/convert.mjs"
      if vim.fn.filereadable(resolved) == 1 then
        return resolved
      end
    end
  end
  return nil
end

function M.ensure_installed()
  if not config.options.auto_install_deps then
    return true
  end
  if not installing then
    if not M.is_installed() then
      M.install()
      return false
    end
    local src = find_convert_mjs()
    if src then
      vim.fn.system({ "cp", src, M.node_dir() .. "/convert.mjs" })
    end
  end
  return M.is_installed()
end

function M.install(callback)
  if installing then
    if callback then
      table.insert(install_callbacks, callback)
    end
    return
  end

  installing = true
  vim.notify("[curl-converter] Installing curlconverter dependency via npm...", vim.log.levels.INFO)

  local dir = M.node_dir()
  vim.fn.mkdir(dir, "p")

  local package_json_path = dir .. "/package.json"
  if vim.fn.filereadable(package_json_path) == 0 then
    local content = vim.fn.json_encode({
      name = "curl-converter-nvim-node",
      type = "module",
      private = true,
      dependencies = { curlconverter = "^4.12.0" },
    })
    vim.fn.writefile(vim.split(content, "\n", { plain = true }), package_json_path)
  end

  local src = find_convert_mjs()
  if src then
    vim.fn.system({ "cp", src, dir .. "/convert.mjs" })
  else
    vim.notify("[curl-converter] Could not find convert.mjs to copy", vim.log.levels.WARN)
  end

  local env = vim.fn.extend(vim.fn.environ(), { CXXFLAGS = "-std=c++20" })

  vim.fn.jobstart(
    { "npm", "install", "--prefix", dir, "--no-audit", "--no-fund" },
    {
      env = env,
      on_exit = function(_, code)
        installing = false
        local success = code == 0
        if success then
          vim.notify("[curl-converter] curlconverter installed successfully", vim.log.levels.INFO)
        else
          vim.notify(
            "[curl-converter] Failed to install curlconverter. Try: CXXFLAGS='-std=c++20' npm install --prefix "
              .. dir
              .. " curlconverter",
            vim.log.levels.ERROR
          )
        end
        local cbs = install_callbacks
        install_callbacks = {}
        for _, cb in ipairs(cbs) do
          pcall(cb, success)
        end
      end,
    }
  )
end

return M
