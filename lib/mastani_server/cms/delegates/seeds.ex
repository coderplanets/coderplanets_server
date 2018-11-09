defmodule MastaniServer.CMS.Delegate.Seeds do
  @moduledoc """
  seeds data for init, should be called ONLY in new database, like migration
  """

  # import Ecto.Query, warn: false
  # import MastaniServer.CMS.Utils.Matcher
  # import Helper.Utils, only: [done: 1, map_atom_value: 2]
  # import MastaniServer.CMS.Delegate.ArticleCURD, only: [ensure_author_exists: 1]
  import ShortMaps

  alias Helper.ORM
  # alias Helper.QueryBuilder
  alias MastaniServer.{Accounts, CMS}
  alias MastaniServer.CMS.{Community, Thread, Category}

  @default_threads ["post", "user", "job", "video", "wiki", "cheatsheet", "repo"]
  @home_addon_threads ["city", "share", "news"]

  @pl_communities ["javascript", "scala", "haskell", "swift", "typescript", "lua", "racket"]
  @default_categories ["pl", "front-end", "back-end", "ai", "design", "mobile", "others"]

  def seed_threads(:default) do
    with true <- is_empty_db?(CMS.Thread) do
      Enum.each(@default_threads, fn thread ->
        title = thread
        raw = thread
        {:ok, _thread} = CMS.create_thread(~m(title raw)a)
      end)

      ORM.find_all(CMS.Thread, %{page: 1, size: 20})
    end
  end

  def seed_categories(bot, :default) do
    with true <- is_empty_db?(Category) do
      Enum.each(@default_categories, fn cat ->
        title = cat
        raw = cat
        CMS.create_category(%Category{title: title, raw: raw}, bot)
      end)

      ORM.find_all(Category, %{page: 1, size: 20})
    end
  end

  def seed_communities(:pl) do
    with {:ok, threads} <- seed_threads(:default),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :pl) do
      threadify_communities(communities, threads)
      categorify_communities(communities, categories)
      # {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: category.id})
    end
  end

  # seed a bot user
  defp seed_bot do
    # TODO: check bot exsit?
    nickname = "cps_bot_2398614_2018"
    avatar = "https://avatars1.githubusercontent.com/u/6184465?s=460&v=4"

    Accounts.User |> ORM.create(~m(nickname avatar)a)
  end

  # seed raw communities, without thread or categories staff
  defp seed_for_communities(bot, :pl) do
    with true <- is_empty_db?(CMS.Community) do
      Enum.each(@pl_communities, fn c ->
        args = %{
          title: c,
          desc: "yes, #{c} is awesome!",
          logo: "https://coderplanets.oss-cn-beijing.aliyuncs.com/icons/pl/#{c}.svg",
          raw: c,
          user_id: bot.id
        }

        Community |> ORM.create(args)
      end)

      ORM.find_all(CMS.Community, %{page: 1, size: 20})
    end
  end

  # set threads to given communities
  defp threadify_communities(communities, threads) do
    Enum.each(communities, fn community ->
      Enum.each(threads, fn thread ->
        {:ok, _} = CMS.set_thread(%Community{id: community.id}, %Thread{id: thread.id})
      end)
    end)
  end

  # set categories to given communities
  defp categorify_communities(communities, categories) do
    Enum.each(communities, fn community ->
      Enum.each(categories, fn cat ->
        {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: cat.id})
      end)
    end)
  end

  # check is the seeds alreay runed
  defp is_empty_db?(queryable) do
    {:ok, results} = ORM.find_all(queryable, %{page: 1, size: 20})
    results.total_count == 0
  end
end
