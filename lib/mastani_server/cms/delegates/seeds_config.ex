defmodule MastaniServer.CMS.Delegate.SeedsConfig do
  @moduledoc """
  init config for seeds
  """

  @doc """
  default seeds for pragraming lang's communities
  """
  # png: reason
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

  # png: backbone, eggjs
  def communities(:framework) do
    [
      "backbone",
      "d3",
      "django",
      "drupal",
      "eggjs",
      "electron",
      "ionic",
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
      "android",
      "ios",
      "tensorflow",
      # new
      "rxjs",
      "flutter",
      "taro",
      "webrtc",
      "wasm"
    ]
  end

  def communities(:design) do
    ["css", "antd"]
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
    ["git", "cps-support", "docker", "kubernetes"]
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
        title: "design",
        raw: "design",
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

  def threads(:default) do
    [
      %{
        title: "post",
        raw: "post",
        index: 0
      },
      %{
        title: "video",
        raw: "video",
        index: 5
      },
      %{
        title: "repo",
        raw: "repo",
        index: 10
      },
      %{
        title: "user",
        raw: "user",
        index: 15
      },
      %{
        title: "wiki",
        raw: "wiki",
        index: 20
      },
      %{
        title: "cheatsheet",
        raw: "cheatsheet",
        index: 25
      },
      %{
        title: "job",
        raw: "job",
        index: 30
      }
    ]
  end

  @doc """
  city threads seeds
  """
  def threads(:city, :list) do
    ["post", "user", "group", "company", "job"]
  end

  @doc """
  default threads seeds for home
  """
  def threads(:home, :list) do
    ["post", "tech", "user", "radar", "city", "share", "job"]
  end

  @doc """
  default tags for general communities
  currently only support post, job, video, repo
  """
  def tags(:post) do
    [
      %{
        title: "refined",
        color: :red
      },
      %{
        title: "share",
        color: :orange
      },
      %{
        title: "ask",
        color: :yellow
      },
      %{
        title: "newbie",
        color: :green
      },
      %{
        title: "algorithm",
        color: :cyan
      },
      %{
        title: "hangout",
        color: :blue
      },
      %{
        title: "spread",
        color: :purple
      },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, topic: "posts"}, attr) end)
  end

  def tags(:job) do
    city_tags()
    |> Map.merge(%{
      title: "remote",
      color: :cadetblue
    })
    |> Enum.map(fn attr -> Map.merge(%{thread: :job, topic: "jobs"}, attr) end)
  end

  def tags(:repo) do
    [
      %{
        title: "framework",
        color: :red
      },
      %{
        title: "devops",
        color: :orange
      },
      %{
        title: "ai",
        color: :yellow
      },
      %{
        title: "test",
        color: :green
      },
      %{
        title: "product",
        color: :cyan
      },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :repo, topic: "repos"}, attr) end)
  end

  def tags(:video) do
    [
      %{
        title: "refined",
        color: :red
      },
      %{
        title: "conf",
        color: :orange
      },
      %{
        title: "tuts",
        color: :yellow
      },
      %{
        title: "safe",
        color: :green
      },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :video, topic: "videos"}, attr) end)
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
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, topic: "posts"}, attr) end)
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
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, topic: "posts"}, attr) end)
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
    |> Enum.map(fn attr -> Map.merge(%{thread: :tech, topic: "tech"}, attr) end)
  end

  def tags(:home, :share) do
    [
      %{
        title: "refined",
        color: :red
      },
      %{
        title: "product",
        color: :orange
      },
      %{
        title: "design",
        color: :yellow
      },
      %{
        # 个人作品
        title: "personal-project",
        color: :green
      },
      %{
        title: "tools-libs",
        color: :cyan
      },
      # %{
      # title: "architecture",
      # color: :blue
      # },
      # %{
      # title: "spread",
      # color: :purple
      # },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :share, topic: "share"}, attr) end)
  end

  def tags(:home, :radar) do
    [
      %{
        title: "science",
        color: :red
      },
      %{
        # 业界
        title: "tech",
        color: :orange
      },
      %{
        title: "hardware",
        color: :yellow
      },
      %{
        title: "games",
        color: :green
      },
      %{
        title: "apple",
        color: :cyan
      },
      %{
        title: "startup",
        color: :blue
      },
      %{
        title: "safe",
        color: :purple
      },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :radar, topic: "radar"}, attr) end)
  end

  def tags(:home, :city) do
    city_tags()
    |> Enum.map(fn attr -> Map.merge(%{thread: :city, topic: "city"}, attr) end)
  end

  def tags(:home, :job) do
    city_tags()
    |> Map.merge(%{
      title: "remote",
      color: :cadetblue
    })
    |> Enum.map(fn attr -> Map.merge(%{thread: :job, topic: "jobs"}, attr) end)
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
