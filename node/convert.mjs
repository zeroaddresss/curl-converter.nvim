import * as cc from "curlconverter";

const langMap = {
  python: "toPythonWarn",
  "python-http": "toPythonHttpWarn",
  javascript: "toJavaScriptWarn",
  "javascript-jquery": "toJavaScriptJqueryWarn",
  "javascript-xhr": "toJavaScriptXHRWarn",
  node: "toNodeWarn",
  "node-axios": "toNodeAxiosWarn",
  "node-got": "toNodeGotWarn",
  "node-ky": "toNodeKyWarn",
  "node-fetch": "toNodeFetchWarn",
  "node-request": "toNodeRequestWarn",
  "node-superagent": "toNodeSuperAgentWarn",
  "node-http": "toNodeHttpWarn",
  go: "toGoWarn",
  rust: "toRustWarn",
  php: "toPhpWarn",
  "php-guzzle": "toPhpGuzzleWarn",
  "php-requests": "toPhpRequestsWarn",
  ruby: "toRubyWarn",
  "ruby-httparty": "toRubyHttpartyWarn",
  java: "toJavaWarn",
  "java-httpurlconnection": "toJavaHttpUrlConnectionWarn",
  "java-jsoup": "toJavaJsoupWarn",
  "java-okhttp": "toJavaOkHttpWarn",
  csharp: "toCSharpWarn",
  swift: "toSwiftWarn",
  objc: "toObjectiveCWarn",
  dart: "toDartWarn",
  kotlin: "toKotlinWarn",
  powershell: "toPowershellRestMethodWarn",
  "powershell-webrequest": "toPowershellWebRequestWarn",
  http: "toHTTPWarn",
  httpie: "toHttpieWarn",
  wget: "toWgetWarn",
  ansible: "toAnsibleWarn",
  c: "toCWarn",
  cfml: "toCFMLWarn",
  clojure: "toClojureWarn",
  elixir: "toElixirWarn",
  har: "toHarStringWarn",
  json: "toJsonStringWarn",
  julia: "toJuliaWarn",
  lua: "toLuaWarn",
  matlab: "toMATLABWarn",
  ocaml: "toOCamlWarn",
  perl: "toPerlWarn",
  r: "toRWarn",
  "r-httr2": "toRHttr2Warn",
};

const langArg = process.argv.find((a) => a.startsWith("--language="));
const lang = langArg ? langArg.split("=")[1] : "python";

const warnFnName = langMap[lang];
if (!warnFnName) {
  process.stderr.write("ER:unsupported\n");
  process.exit(1);
}

const warnFn = cc[warnFnName];
if (!warnFn) {
  process.stderr.write("ER:unsupported\n");
  process.exit(1);
}

const stdin = await (async () => {
  const parts = [];
  for await (const chunk of process.stdin) parts.push(chunk);
  return parts.join("");
})();

let input = stdin;
if (!input) {
  const args = process.argv.slice(2).filter((a) => !a.startsWith("--language="));
  if (args.length > 0) {
    input = args.join(" ");
  }
}
if (!input) {
  process.stderr.write("ER:No curl command provided\n");
  process.exit(1);
}

let code, warnings;
try {
  [code, warnings] = warnFn(input);
} catch (e) {
  process.stderr.write("ER:" + e.message + "\n");
  process.exit(1);
}

if (warnings && warnings.length > 0) {
  process.stderr.write("WA:" + JSON.stringify(warnings) + "\n");
}
process.stdout.write(code);
