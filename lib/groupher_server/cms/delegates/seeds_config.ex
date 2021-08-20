defmodule GroupherServer.CMS.Delegate.SeedsConfig do
  alias GroupherServer.CMS
  alias CMS.Model.Community

  @moduledoc """
  init config for seeds
  """
  @tag_colors ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "grey"]

  def random_color(), do: @tag_colors |> Enum.random() |> String.to_atom()

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

  @doc """
  default tags for general communities
  currently only support post, job, repo
  """
  def tags(%Community{raw: "home"}, :post) do
    [
      %{
        title: "求助",
        raw: "help",
        group: "技术与人文"
      },
      %{
        raw: "tech",
        title: "技术",
        group: "技术与人文"
      },
      %{
        raw: "maker",
        title: "创作者",
        group: "技术与人文"
      },
      %{
        raw: "geek",
        title: "极客",
        group: "技术与人文"
      },
      %{
        raw: "IxD",
        title: "交互设计",
        group: "技术与人文"
      },
      %{
        raw: "DF",
        title: "黑暗森林",
        group: "技术与人文"
      },
      %{
        raw: "thoughts",
        title: "迷思",
        group: "技术与人文"
      },
      %{
        raw: "city",
        title: "城市",
        group: "生活与职场"
      },
      %{
        raw: "pantry",
        title: "茶水间",
        group: "生活与职场"
      },
      %{
        raw: "afterwork",
        title: "下班后",
        group: "生活与职场"
      },
      %{
        raw: "WTF",
        title: "吐槽",
        group: "其他"
      },
      %{
        raw: "REC",
        title: "推荐",
        group: "其他"
      },
      %{
        raw: "idea",
        title: "脑洞",
        group: "其他"
      },
      %{
        raw: "feedback",
        title: "站务",
        group: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def tags(%Community{raw: "feedback"}, :post) do
    [
      %{
        title: "Bug",
        raw: "bug"
      },
      %{
        title: "官方公告",
        raw: "official"
      },
      %{
        title: "需求池",
        raw: "demand"
      },
      %{
        title: "内容审核",
        raw: "audit"
      },
      %{
        title: "编辑器",
        raw: "editor"
      },
      %{
        title: "界面交互",
        raw: "UI/UX"
      },
      %{
        title: "使用疑问",
        raw: "ask"
      },
      %{
        title: "周报",
        raw: "changelog"
      },
      %{
        title: "社区治理",
        raw: "manage"
      },
      %{
        title: "其他",
        raw: "others"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def tags(%Community{raw: "blockhole"}, :post) do
    [
      %{
        title: "传单",
        raw: "flyer"
      },
      %{
        title: "标题党",
        raw: "clickbait"
      },
      %{
        title: "封闭平台",
        raw: "ugly"
      },
      %{
        raw: "pirated",
        title: "盗版 & 侵权"
      },
      %{
        raw: "copycat",
        title: "水贴"
      },
      %{
        raw: "no-good",
        title: "坏问题"
      },
      %{
        raw: "illegal",
        title: "无法无天"
      },
      %{
        raw: "others",
        title: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def tags(%Community{raw: "makers"}, :post) do
    [
      %{
        title: "求教",
        raw: "ask",
        group: "讨论"
      },
      %{
        title: "推荐",
        raw: "REC",
        group: "讨论"
      },
      %{
        title: "生活",
        raw: "life",
        group: "讨论"
      },
      %{
        title: "脑洞",
        raw: "idea",
        group: "讨论"
      },
      %{
        title: "打招呼",
        raw: "say-hey",
        group: "讨论"
      },
      %{
        title: "小聚",
        raw: "meetup",
        group: "讨论"
      },
      %{
        title: "技术选型",
        raw: "arch",
        group: "产品打磨"
      },
      %{
        title: "即时分享",
        raw: "share",
        group: "产品打磨"
      },
      %{
        title: "App 上架",
        raw: "app",
        group: "合规问题"
      },
      %{
        title: "合规 & 资质",
        raw: "law",
        group: "合规问题"
      },
      %{
        title: "域名",
        raw: "domain",
        group: "其他"
      },
      %{
        title: "吐槽",
        raw: "WTF",
        group: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def tags(%Community{raw: "adwall"}, :post) do
    [
      %{
        title: "产品推广",
        raw: "advertise"
      },
      %{
        title: "推荐 & 抽奖",
        raw: "discount"
      },
      %{
        title: "培训 & 课程",
        raw: "class"
      },
      %{
        title: "资料",
        raw: "collect"
      },
      %{
        title: "奇奇怪怪",
        raw: "others"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def tags(:job) do
    city_tags()
    |> Enum.concat([
      %{
        title: "remote",
        color: :cadetblue
      }
    ])
    |> Enum.map(fn attr -> Map.merge(%{thread: :job}, attr) end)
  end

  def tags(_), do: []

  def tags(:city, :post) do
    [
      %{
        title: "refined",
        color: :red
      },
      %{
        title: "workplace",
        color: :orange
      },
      %{
        title: "ask",
        color: :yellow
      },
      %{
        title: "activity",
        color: :green
      },
      %{
        title: "2hand",
        color: :cyan
      },
      %{
        title: "hangout",
        color: :blue
      },
      # %{
      # title: "spread",
      # color: :purple
      # },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post}, attr) end)
  end

  # home posts
  def tags(:home, :post) do
    [
      %{
        title: "refined",
        color: :red
      },
      %{
        title: "design",
        color: :orange
      },
      %{
        title: "ask",
        color: :yellow
      },
      %{
        title: "workplace",
        color: :green
      },
      %{
        title: "3c",
        color: :cyan
      },
      %{
        title: "hangout",
        color: :blue
      },
      # %{
      # title: "spread",
      # color: :purple
      # },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post}, attr) end)
  end

  def tags(:home, :tech) do
    [
      %{
        title: "frontend",
        color: :red
      },
      %{
        title: "backend",
        color: :orange
      },
      %{
        title: "mobile",
        color: :yellow
      },
      %{
        title: "operation",
        color: :green
      },
      %{
        title: "blockchain",
        color: :cyan
      },
      %{
        title: "db",
        color: :blue
      },
      %{
        title: "ai",
        color: :purple
      },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :tech}, attr) end)
  end

  def tags(:home, :job) do
    city_tags()
    |> Enum.concat([
      %{
        title: "remote",
        color: :cadetblue
      }
    ])
    |> Enum.map(fn attr -> Map.merge(%{thread: :job}, attr) end)
  end

  def tags(:home, _), do: []

  defp city_tags do
    [
      %{
        title: "beijing",
        color: :red
      },
      %{
        title: "shanghai",
        color: :orange
      },
      %{
        title: "shenzhen",
        color: :yellow
      },
      %{
        title: "hangzhou",
        color: :green
      },
      %{
        title: "guangzhou",
        color: :cyan
      },
      %{
        title: "chengdu",
        color: :blue
      },
      %{
        title: "wuhan",
        color: :purple
      },
      %{
        title: "nanjing",
        color: :yellowgreen
      },
      %{
        title: "xiamen",
        color: :dodgerblue
      },
      %{
        title: "oversea",
        color: :brown
      },
      %{
        title: "other",
        color: :grey
      }
    ]
  end
end
