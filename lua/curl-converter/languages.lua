local M = {}

M.groups = {
  {
    name = "Python",
    items = {
      { label = "Python + Requests",    value = "python" },
      { label = "Python + http.client", value = "python-http" },
    },
  },
  {
    name = "JavaScript / Node.js",
    items = {
      { label = "JavaScript + fetch",   value = "javascript" },
      { label = "JavaScript + jQuery",  value = "javascript-jquery" },
      { label = "JavaScript + XHR",     value = "javascript-xhr" },
      { label = "Node.js + fetch",      value = "node" },
      { label = "Node.js + Axios",      value = "node-axios" },
      { label = "Node.js + Got",        value = "node-got" },
      { label = "Node.js + Ky",         value = "node-ky" },
      { label = "Node.js + node-fetch", value = "node" },
      { label = "Node.js + request",    value = "node-request" },
      { label = "Node.js + SuperAgent", value = "node-superagent" },
      { label = "Node.js + http",       value = "node-http" },
    },
  },
  {
    name = "Go",
    items = {
      { label = "Go", value = "go" },
    },
  },
  {
    name = "Rust",
    items = {
      { label = "Rust", value = "rust" },
    },
  },
  {
    name = "PHP",
    items = {
      { label = "PHP + cURL",     value = "php" },
      { label = "PHP + Guzzle",   value = "php-guzzle" },
      { label = "PHP + Requests", value = "php-requests" },
    },
  },
  {
    name = "Ruby",
    items = {
      { label = "Ruby + Net::HTTP", value = "ruby" },
      { label = "Ruby + HTTParty",  value = "ruby-httparty" },
    },
  },
  {
    name = "Java",
    items = {
      { label = "Java + HttpClient",          value = "java" },
      { label = "Java + HttpURLConnection",   value = "java-httpurlconnection" },
      { label = "Java + jsoup",               value = "java-jsoup" },
      { label = "Java + OkHttp",              value = "java-okhttp" },
    },
  },
  {
    name = "C# / .NET",
    items = {
      { label = "C#", value = "csharp" },
    },
  },
  {
    name = "Shell / CLI",
    items = {
      { label = "HTTP",      value = "http" },
      { label = "HTTPie",    value = "httpie" },
      { label = "Wget",      value = "wget" },
    },
  },
  {
    name = "PowerShell",
    items = {
      { label = "PowerShell + Invoke-RestMethod",  value = "powershell" },
      { label = "PowerShell + Invoke-WebRequest",  value = "powershell-webrequest" },
    },
  },
  {
    name = "Mobile",
    items = {
      { label = "Swift",       value = "swift" },
      { label = "Objective-C", value = "objc" },
      { label = "Dart",        value = "dart" },
    },
  },
  {
    name = "Other",
    items = {
      { label = "Ansible",  value = "ansible" },
      { label = "C",        value = "c" },
      { label = "Clojure",  value = "clojure" },
      { label = "ColdFusion", value = "cfml" },
      { label = "Elixir",   value = "elixir" },
      { label = "JSON",     value = "json" },
      { label = "Julia",    value = "julia" },
      { label = "Kotlin",   value = "kotlin" },
      { label = "Lua",      value = "lua" },
      { label = "MATLAB",   value = "matlab" },
      { label = "OCaml",    value = "ocaml" },
      { label = "Perl",     value = "perl" },
      { label = "R + httr", value = "r" },
      { label = "R + httr2", value = "r-httr2" },
      { label = "HAR",      value = "har" },
    },
  },
}

local all_items = {}
for _, group in ipairs(M.groups) do
  for _, item in ipairs(group.items) do
    all_items[item.value] = item
  end
end

function M.resolve_label(value)
  local item = all_items[value]
  return item and item.label or value
end

return M
