if vim.g.loaded_curl_converter then
  return
end
vim.g.loaded_curl_converter = true

require("curl-converter")
