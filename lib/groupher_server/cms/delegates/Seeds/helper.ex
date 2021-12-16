defmodule GroupherServer.CMS.Delegate.Seeds.Helper do
  @moduledoc false

  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import ShortMaps

  alias GroupherServer.{Accounts, CMS}
  alias CMS.Delegate.{Seeds, SeedsConfig}
  alias CMS.Model.{Community, Thread, Category}

  alias Accounts.Model.User
  alias Helper.ORM

  @categories Seeds.Categories.get()

  # set threads to given communities
  def threadify_communities(communities, threads) when is_list(communities) do
    Enum.each(communities, fn community ->
      Enum.each(threads, fn thread ->
        {:ok, _} = CMS.set_thread(%Community{id: community.id}, %Thread{id: thread.id})
      end)
    end)
  end

  # create tags

  def tagfy_threads(communities, threads, bot, type) when is_list(communities) do
    Enum.each(communities, fn community ->
      Enum.each(threads, fn thread ->
        create_tags(community, thread, bot, type)
      end)
    end)
  end

  def create_tags(%Community{} = community, %Thread{raw: raw}, bot, type) do
    thread = raw |> String.to_atom()

    Enum.each(
      Seeds.Tags.get(community, thread, type),
      &CMS.create_article_tag(community, thread, &1, bot)
    )
  end

  # create tags end

  def categorify_communities(communities, categories, :editor) do
    categorify_communities(communities, categories, :tools)
  end

  # set categories to given communities
  def categorify_communities(communities, categories, part)
      when is_list(communities) and is_atom(part) do
    the_category = categories.entries |> Enum.find(fn cat -> cat.raw == Atom.to_string(part) end)

    Enum.each(communities, fn community ->
      {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: the_category.id})
    end)
  end

  # seed community end

  # seed thread
  def seed_threads(type) do
    threads = Seeds.Threads.get(type)
    threads_list = threads |> Enum.map(& &1.raw)

    threads
    |> Enum.each(fn thread ->
      with {:error, _} <- ORM.find_by(Thread, %{raw: thread.raw}) do
        CMS.create_thread(thread)
      end
    end)

    Thread
    |> where([t], t.raw in ^threads_list)
    |> ORM.paginator(page: 1, size: 10)
    |> done()
  end

  # seed thread end

  def seed_categories_ifneed(bot) do
    with true <- is_empty_in_db?(Category) do
      Enum.each(@categories, &CMS.create_category(&1, bot))
    end

    ORM.find_all(Category, %{page: 1, size: 20})
  end

  def seed_user(name) do
    nickname = name
    login = name
    avatar = "https://avatars1.githubusercontent.com/u/6184465?s=460&v=4"

    User |> ORM.findby_or_insert(~m(nickname avatar)a, ~m(nickname avatar login)a)
  end

  def seed_bot() do
    case ORM.find(User, 1) do
      {:ok, user} ->
        {:ok, user}

      {:error, _} ->
        nickname = "cps_bot_2398614_2018"
        login = "cp_bot"
        avatar = "https://avatars1.githubusercontent.com/u/6184465?s=460&v=4"

        User |> ORM.findby_or_insert(~m(nickname avatar)a, ~m(nickname avatar login)a)
    end
  end

  # check is the seeds alreay runed
  def is_empty_in_db?(queryable) do
    {:ok, results} = ORM.find_all(queryable, %{page: 1, size: 20})
    results.total_count == 0
  end

  def insert_community(bot, raw, type) do
    type = Atom.to_string(type)
    ext = if Enum.member?(SeedsConfig.svg_icons(), raw), do: "svg", else: "png"

    args = %{
      title: SeedsConfig.trans(raw),
      aka: raw,
      desc: "#{raw} is awesome!",
      logo: "#{@oss_endpoint}/icons/#{type}/#{raw}.#{ext}",
      raw: raw,
      user_id: bot.id
    }

    ORM.create(Community, args)
  end
end
