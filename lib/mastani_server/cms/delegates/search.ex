defmodule MastaniServer.CMS.Delegate.Search do
  @moduledoc """
  search for community, post, job ...
  """

  import Helper.Utils, only: [done: 1]
  import Ecto.Query, warn: false

  alias Helper.ORM
  alias MastaniServer.CMS.{Community, Post, Job, Video, Repo}

  @search_items_count 15

  @doc """
  search community by title
  """
  def search_items(:community, %{title: title} = _args) do
    Community
    |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.raw, ^"%#{title}%"))
    |> ORM.paginater(page: 1, size: @search_items_count)
    |> done()
  end

  @doc """
  search post by title
  """
  def search_items(:post, %{title: title} = _args) do
    Post
    |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.digest, ^"%#{title}%"))
    |> ORM.paginater(page: 1, size: @search_items_count)
    |> done()
  end

  @doc """
  search job by title or company name
  """
  def search_items(:job, %{title: title} = _args) do
    Job
    |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.company, ^"%#{title}%"))
    |> ORM.paginater(page: 1, size: @search_items_count)
    |> done()
  end

  @doc """
  search video by title
  """
  def search_items(:video, %{title: title} = _args) do
    Video
    |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.desc, ^"%#{title}%"))
    |> ORM.paginater(page: 1, size: @search_items_count)
    |> done()
  end

  @doc """
  search repo by title
  """
  def search_items(:repo, %{title: title} = _args) do
    Repo
    |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.owner_name, ^"%#{title}%"))
    |> ORM.paginater(page: 1, size: @search_items_count)
    |> done()
  end
end
