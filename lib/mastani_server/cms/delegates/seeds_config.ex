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
  def threads(:default), do: ["post", "user", "job", "video", "wiki", "cheatsheet", "repo"]

  @doc """
  default threads seeds for home
  """
  def threads(:home), do: ["post", "user", "news", "city", "share", "job"]

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
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post}, attr) end)
  end

  def tags(:job) do
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
        title: "chengdu",
        color: :cyan
      },
      %{
        title: "wuhan",
        color: :blue
      },
      %{
        title: "oversea",
        color: :purple
      },
      %{
        title: "other",
        color: :grey
      }
    ]
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

  def tags(_), do: []
end
