# curl-converter.nvim

Convert cURL commands to Python, JavaScript, Go, Rust, PHP, Ruby, Java, C#, Swift, and 25+ other languages — directly inside NeoVim.

Powered by the same engine as [curlconverter.com](https://curlconverter.com).

## Requirements

- NeoVim >= 0.10
- Node.js >= 18
- Optional: telescope.nvim for fuzzy language search

## Installation

**lazy.nvim**:

```lua
{
  "zeroaddresss/curl-converter.nvim",
  cmd = { "CurlConvert", "CurlConvertPaste", "CurlConvertInstall" },
  opts = {},
}
```

**packer.nvim**:

```lua
use {
  "zeroaddresss/curl-converter.nvim",
  config = function()
    require("curl-converter").setup({})
  end,
}
```

**vim-plug**:

```vim
Plug "zeroaddresss/curl-converter.nvim"
lua require("curl-converter").setup({})
```

## Quick Start

1. `CurlConvert<CR>`
2. Paste your curl command in the input buffer
3. Press `<CR>` to confirm
4. Select the target language from the picker (Telescope is used when installed)
5. Press `y` to yank the result and close

Or use `:CurlConvertPaste` to skip straight to language selection if you already have a curl command in your clipboard.
Use `:CurlConvertInstall` to manually install or reinstall the curlconverter npm dependency.

## Commands

| Command | Description |
|---|---|
| `:CurlConvert` | Open input buffer, select language, show result |
| `:CurlConvertPaste` | Use clipboard curl command directly |
| `:CurlConvertInstall` | (Re)install curlconverter npm dependency |

## Keymaps

**Input buffer**: `<CR>` confirm, `<Esc>` cancel.

**Output window**: `y`/`Y` yank, `r` re-select, `q` close.

## Supported Languages

Python (Requests, http.client), JavaScript (fetch, jQuery, XHR), Node.js (fetch, Axios, Got, Ky, request, SuperAgent, http), Go, Rust, PHP (cURL, Guzzle, Requests), Ruby (Net::HTTP, HTTParty), Java (HttpClient, HttpURLConnection, jsoup, OkHttp), C#, Swift, Objective-C, Dart, Kotlin, PowerShell (Invoke-RestMethod, Invoke-WebRequest), CLI (HTTP, HTTPie, Wget), Ansible, C, Clojure, ColdFusion, Elixir, JSON, Julia, Lua, MATLAB, OCaml, Perl, R (httr, httr2), HAR.

## Configuration

```lua
require("curl-converter").setup({
  node_path = "node",           -- Path to Node.js binary
  auto_install_deps = true,     -- Auto-install npm deps
  output_window = {
    border = "rounded",         -- Border style
    width = 0.8,                -- Width fraction
    height = 0.8,               -- Height fraction
  },
  keymaps = {
    close = "q",
    yank = "y",
    reselect = "r",
  },
})
```

## License

MIT
