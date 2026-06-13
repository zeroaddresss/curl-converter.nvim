local config = require("curl-converter.config")
local installer = require("curl-converter.installer")

local M = {}

local pending_queue = {}

function M.convert_async(curl_cmd, language, callback)
  if not installer.is_installed() then
    if installer.is_installing() then
      installer.on_install_complete(function(success)
        if success then
          M.convert_async(curl_cmd, language, callback)
        else
          callback(nil, "curlconverter installation failed", nil)
        end
      end)
      return
    end
    callback(nil, "curlconverter not installed. Run :CurlConvertInstall", nil)
    return
  end

  local dir = installer.node_dir()
  local script = dir .. "/convert.mjs"
  if vim.fn.filereadable(script) == 0 then
    callback(nil, "convert.mjs not found in " .. dir, nil)
    return
  end

  vim.system(
    { config.options.node_path, script, "--language=" .. language },
    { stdin = curl_cmd },
    function(obj)
      local code = obj.stdout or ""
      local stderr = obj.stderr or ""
      local warnings = nil
      local error_msg = nil

      if stderr ~= "" then
        for _, line in ipairs(vim.split(stderr, "\n", { plain = true })) do
          if line:match("^ER:") then
            local rest = line:gsub("^ER:", "")
            if rest == "unsupported" then
              error_msg = "Unsupported language: " .. language
            else
              error_msg = rest
            end
          elseif line:match("^WA:") then
            local json_str = line:gsub("^WA:", "")
            local ok, parsed = pcall(vim.json.decode, json_str)
            if ok and type(parsed) == "table" then
              if warnings then
                vim.list_extend(warnings, parsed)
              else
                warnings = parsed
              end
            end
          end
        end
      end

      if error_msg then
        callback(nil, error_msg, nil)
        return
      end

      if obj.code ~= 0 and code == "" and not error_msg then
        callback(nil, "Conversion failed (exit code " .. obj.code .. ")", nil)
        return
      end

      callback(code, nil, warnings)
    end
  )
end

function M.convert(curl_cmd, language)
  local result = {}
  M.convert_async(curl_cmd, language, function(code, err, warnings)
    result.code = code
    result.err = err
    result.warnings = warnings
  end)
  vim.wait(30000, function() return result.code ~= nil or result.err ~= nil end, 10)
  return result.code, result.err, result.warnings
end

return M
