defmodule GroupherServer.CMS.Delegate.Seeds.Communities do
  @moduledoc """
  communities seeds
  """

  def get(:pl) do
    [
      "c",
      "clojure",
      "cpp",
      "csharp",
      "dart",
      "delphi",
      "elm",
      "erlang",
      "fsharp",
      "go",
      "gradle",
      "groovy",
      "java",
      "javascript",
      "julia",
      "kotlin",
      "lisp",
      "lua",
      "ocaml",
      "perl",
      "php",
      "python",
      "ruby",
      "r",
      "racket",
      "red",
      "reason",
      "rust",
      "scala",
      "haskell",
      "swift",
      "typescript",
      "elixir",
      # new
      "deno",
      "crystal",
      "hack",
      "nim",
      "fasm",
      "zig",
      "prolog"
    ]
  end

  def get(:framework) do
    [
      "backbone",
      "d3",
      "django",
      "drupal",
      "eggjs",
      "electron",
      "laravel",
      "meteor",
      "nestjs",
      "nuxtjs",
      "nodejs",
      "phoenix",
      "rails",
      "react",
      "sails",
      "zend",
      "vue",
      "angular",
      "tensorflow",
      # mobile
      "android",
      "ios",
      "react-native",
      "weex",
      "xamarin",
      "nativescript",
      "ionic",
      # new
      "rxjs",
      "flutter",
      "taro",
      "webrtc",
      "wasm"
    ]
  end

  def get(:editor) do
    ["vim", "atom", "emacs", "vscode", "visualstudio", "jetbrains"]
  end

  def get(:database) do
    [
      "oracle",
      "hive",
      "spark",
      "hadoop",
      "cassandra",
      "elasticsearch",
      "sql-server",
      "neo4j",
      "mongodb",
      "mysql",
      "postgresql",
      "redis"
    ]
  end

  def get(:city) do
    [
      "beijing",
      "shanghai",
      "shenzhen",
      "hangzhou",
      "guangzhou",
      "chengdu",
      "wuhan",
      "xiamen",
      "nanjing"
    ]
  end

  def get(:devops) do
    # gcp -> google-cloud-platform
    # search google: devops tools
    ["git", "docker", "kubernetes", "jenkins", "puppet", "aws", "azure", "aliyun", "gcp"]
  end
end
