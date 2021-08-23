defmodule GroupherServer.CMS.Delegate.Seeds do
  @moduledoc """
  seeds data for init, should be called ONLY in new database, like migration
  """

  import Helper.Utils, only: [done: 1]
  import Ecto.Query, warn: false

  @oss_endpoint "https://cps-oss.oss-cn-shanghai.aliyuncs.com"
  # import Helper.Utils, only: [done: 1, map_atom_value: 2]
  # import GroupherServer.CMS.Delegate.ArticleCURD, only: [ensure_author_exists: 1]
  import ShortMaps

  alias Helper.ORM
  # alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.{Community, Thread, Category}

  alias CMS.Delegate.SeedsConfig
  alias CMS.Delegate.Seeds
  alias Seeds.Helper

  @pl_communities Seeds.Communities.get(:pl)
  @framework_communities Seeds.Communities.get(:framework)
  @editor_communities Seeds.Communities.get(:editor)
  @database_communities Seeds.Communities.get(:database)
  @devops_communities Seeds.Communities.get(:devops)
  # categories
  @categories Seeds.Categories.get()

  @community_types [:pl, :framework, :editor, :database, :devops, :city]

  # seed community

  @doc """
  seed communities pragraming languages
  """
  def seed_communities(type) when type in @community_types do
    Seeds.Communities.get(type) |> Enum.each(&seed_community(&1, type)) |> done
  end

  @doc """
  seed community for home
  """
  def seed_community(:home) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "home"}),
         {:ok, bot} <- seed_bot(),
         {:ok, threads} <- seed_threads(:home),
         {:ok, categories} <- seed_categories_ifneed(bot) do
      args = %{
        title: "coderplanets",
        desc: "the most sexy community for developers, ever.",
        logo: "#{@oss_endpoint}/icons/cmd/keyboard_logo.png",
        raw: "home",
        user_id: bot.id
      }

      {:ok, community} = Community |> ORM.create(args)
      threadify_communities([community], threads.entries)
      tagfy_threads([community], threads.entries, bot, :home)

      {:ok, community}
      # home 不设置分类，比较特殊
    end
  end

  @doc """
  seed community for home
  """
  def seed_community(:blackhole) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "blackhole"}),
         {:ok, bot} <- seed_bot(),
         {:ok, threads} <- seed_threads(:blackhole),
         {:ok, categories} <- seed_categories_ifneed(bot) do
      args = %{
        title: "黑洞",
        desc: "这里收录不适合出现在本站的内容。",
        logo: "#{@oss_endpoint}/icons/cmd/keyboard_logo.png",
        raw: "blackhole",
        user_id: bot.id
      }

      {:ok, community} = Community |> ORM.create(args)
      threadify_communities([community], threads.entries)
      tagfy_threads([community], threads.entries, bot, :blackhole)
      categorify_communities([community], categories, :others)

      {:ok, community}
      # home 不设置分类，比较特殊
    end
  end

  # type: city, pl, framework, ...
  def seed_community(raw, type) when type in @community_types do
    with {:ok, threads} <- seed_threads(type),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories_ifneed(bot),
         {:ok, community} <- Helper.insert_community(bot, raw, type) do
      threadify_communities([community], threads.entries)
      tagfy_threads([community], threads.entries, bot, type)
      categorify_communities([community], categories, type)

      {:ok, community}
    end
  end

  def seed_community(_raw, _type), do: "undown community type"

  # seed community end

  # seed thread
  def seed_threads(:city), do: do_seed_threads(:city)
  def seed_threads(:pl), do: do_seed_threads(:pl)
  def seed_threads(:framework), do: do_seed_threads(:framework)

  def seed_threads(:home), do: do_seed_threads(:home)
  def seed_threads(:blackhole), do: do_seed_threads(:blackhole)

  # def seed_threads(:feedback), do: do_seed_threads(:home)
  # def seed_threads(:adwall), do: do_seed_threads(:home)
  # def seed_threads(:blackhole), do: do_seed_threads(:home)

  defp do_seed_threads(type) do
    threads = Seeds.Threads.get(type)
    threads_list = threads |> Enum.map(& &1.raw)

    with {:error, _} <- ORM.find_by(Thread, %{raw: "post"}) do
      threads |> Enum.each(&CMS.create_thread(&1))
    end

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

  @doc """
  set list of communities to a spec category
  """
  def seed_set_category(communities_names, cat_name) when is_list(communities_names) do
    {:ok, category} = ORM.find_by(Category, %{raw: cat_name})

    Enum.each(communities_names, fn name ->
      {:ok, community} = ORM.find_by(Community, %{raw: name})

      {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: category.id})
    end)
  end

  def seed_bot do
    case ORM.find(User, 1) do
      {:ok, user} ->
        {:ok, user}

      {:error, _} ->
        nickname = "cps_bot_2398614_2018"
        avatar = "https://avatars1.githubusercontent.com/u/6184465?s=460&v=4"

        User |> ORM.findby_or_insert(~m(nickname avatar)a, ~m(nickname avatar)a)
    end
  end

  # set threads to given communities
  defp threadify_communities(communities, threads) when is_list(communities) do
    Enum.each(communities, fn community ->
      Enum.each(threads, fn thread ->
        {:ok, _} = CMS.set_thread(%Community{id: community.id}, %Thread{id: thread.id})
      end)
    end)
  end

  # create tags

  defp tagfy_threads(communities, threads, bot, type) when is_list(communities) do
    Enum.each(communities, fn community ->
      Enum.each(threads, fn thread ->
        create_tags(community, thread, bot, type)
      end)
    end)
  end

  defp create_tags(%Community{} = community, %Thread{raw: raw}, bot, type) do
    thread = raw |> String.to_atom()

    Enum.each(
      Seeds.Tags.get(community, thread, type),
      &CMS.create_article_tag(community, thread, &1, bot)
    )
  end

  # create tags end

  defp categorify_communities(communities, categories, :editor) do
    categorify_communities(communities, categories, :tools)
  end

  # set categories to given communities
  defp categorify_communities(communities, categories, part)
       when is_list(communities) and is_atom(part) do
    the_category = categories.entries |> Enum.find(fn cat -> cat.raw == Atom.to_string(part) end)

    Enum.each(communities, fn community ->
      {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: the_category.id})
    end)
  end

  # check is the seeds alreay runed
  defp is_empty_in_db?(queryable) do
    {:ok, results} = ORM.find_all(queryable, %{page: 1, size: 20})
    results.total_count == 0
  end
end
