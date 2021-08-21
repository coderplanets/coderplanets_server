defmodule GroupherServer.CMS.Delegate.SeedsConfig do
  alias GroupherServer.CMS
  alias CMS.Model.Community

  @moduledoc """
  init config for seeds
  """
  def svg_icons do
    [
      "cps-support",
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

  def trans("beijing"), do: "北京"
  def trans("shanghai"), do: "上海"
  def trans("shenzhen"), do: "深圳"
  def trans("hangzhou"), do: "杭州"
  def trans("guangzhou"), do: "广州"
  def trans("chengdu"), do: "成都"
  def trans("wuhan"), do: "武汉"
  def trans("xiamen"), do: "厦门"
  def trans("nanjing"), do: "南京"
  def trans(c), do: c

  def communities(:pl_patch) do
    [
      # "deno"
      # "crystal"
      # "applescript",
      # "hack",
      # "nim",
      # "fasm",
      # "zig"
      # "prolog"
    ]
  end

  @doc """
  default seeds for pragraming lang"s communities
  """
  def communities(:pl) do
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
      "elixir"
    ]
  end

  def communities(:framework_patch) do
    [
      # "cyclejs"
      # "graphql"
      # "dubbo"
      # "mithril"
      "machine-learning"
    ]
  end

  # png: backbone, eggjs
  def communities(:framework) do
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

  def communities(:ui) do
    ["css", "bootstrap", "semantic-ui", "material-design", "fabric", "antd"]
  end

  def communities(:blockchain) do
    ["ethereum", "bitcoin"]
  end

  def communities(:editor) do
    ["vim", "atom", "emacs", "vscode", "visualstudio", "jetbrains"]
  end

  def communities(:database) do
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

  def communities(:city) do
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

  def communities(:devops) do
    ["git", "feedback", "docker", "kubernetes", "shell"]
  end

  @doc """
  default categories seeds for general community
  """
  def categories(:default) do
    [
      %{
        title: "pl",
        raw: "pl",
        index: 0
      },
      %{
        title: "frontend",
        raw: "frontend",
        index: 3
      },
      %{
        title: "backend",
        raw: "backend",
        index: 6
      },
      %{
        title: "mobile",
        raw: "mobile",
        index: 9
      },
      %{
        title: "ai",
        raw: "ai",
        index: 12
      },
      %{
        title: "ui",
        raw: "ui",
        index: 15
      },
      %{
        title: "blockchain",
        raw: "blockchain",
        index: 18
      },
      %{
        title: "city",
        raw: "city",
        index: 21
      },
      %{
        title: "other",
        raw: "other",
        index: 24
      }
    ]
  end

  # 语言，编程框架等
  def threads(:lang) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "雷达",
        raw: "radar",
        index: 2
      },
      %{
        title: "博客",
        raw: "blog",
        index: 3
      },
      %{
        title: "101",
        raw: "tut",
        index: 20
      },
      %{
        title: "awesome",
        raw: "awesome",
        index: 20
      },
      %{
        title: "作品",
        raw: "works",
        index: 25
      },
      %{
        title: "工作",
        raw: "job",
        index: 30
      },
      %{
        title: "users",
        raw: "users",
        index: 30
      }
    ]
  end

  def threads(:home) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "雷达",
        raw: "radar",
        index: 2
      },
      %{
        title: "博客",
        raw: "blog",
        index: 3
      },
      %{
        title: "工作",
        raw: "job",
        index: 4
      },
      %{
        title: "CPer",
        raw: "users",
        index: 5
      },
      %{
        title: "设置",
        raw: "setting",
        index: 6
      }
    ]
  end

  def threads(:city) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "团队",
        raw: "team",
        index: 2
      },
      %{
        title: "工作",
        raw: "job",
        index: 3
      }
    ]
  end

  def tags(_), do: []
  def tags(_, _), do: []
end
