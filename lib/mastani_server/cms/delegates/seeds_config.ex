defmodule MastaniServer.CMS.Delegate.SeedsConfig do
  @moduledoc """
  init config for seeds
  """

  @doc """
  default seeds for pragraming lang's communities
  """
  def communities(:pl) do
    ["javascript", "scala", "haskell", "swift", "typescript", "lua", "racket"]
  end

  @doc """
  default categories seeds for general community
  """
  def categories(:default),
    do: ["pl", "front-end", "back-end", "ai", "design", "mobile", "others"]

  @doc """
  default threads seeds for general communities
  """
  # ["post", "user", "job", "video", "wiki", "cheatsheet", "repo"]
  def threads(:default) do
    [
      %{
        title: "post",
        raw: 'post',
        index: 0
      },
      %{
        title: "video",
        raw: 'video',
        index: 5
      },
      %{
        title: "repo",
        raw: 'repo',
        index: 10
      },
      %{
        title: "user",
        raw: 'user',
        index: 15
      },
      %{
        title: "wiki",
        raw: 'wiki',
        index: 20
      },
      %{
        title: "cheatsheet",
        raw: 'cheatsheet',
        index: 25
      },
      %{
        title: "job",
        raw: 'job',
        index: 30
      }
    ]
  end

  @doc """
  default threads seeds for home
  """
  def threads(:home, :list) do
    ["post", "user", "news", "city", "share", "job"]
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
    |> Enum.map(fn attr -> Map.merge(%{thread: :post}, attr) end)
  end

  def tags(:job) do
    city_tags()
    |> Enum.map(fn attr -> Map.merge(%{thread: :job}, attr) end)
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
    |> Enum.map(fn attr -> Map.merge(%{thread: :repo}, attr) end)
  end

  def tags(:video) do
    [
      %{
        title: "refined",
        color: :red
      },
      %{
        title: "conf",
        color: :red
      },
      %{
        title: "tuts",
        color: :orange
      },
      %{
        title: "security",
        color: :yellow
      },
      %{
        title: "other",
        color: :grey
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :video}, attr) end)
  end

  # home posts
  def tags(:home, :post) do
    [
      %{
        title: "refined",
        color: :red
      },
      %{
        title: "tech",
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

  def tags(:home, :news) do
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
    |> Enum.map(fn attr -> Map.merge(%{thread: :news, topic: "news"}, attr) end)
  end

  def tags(:home, :city) do
    city_tags()
    |> Enum.map(fn attr -> Map.merge(%{thread: :city, topic: "city"}, attr) end)
  end

  def tags(:home, :job) do
    city_tags()
    |> Enum.map(fn attr -> Map.merge(%{thread: :job, topic: "job"}, attr) end)
  end

  def tags(_), do: []
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
