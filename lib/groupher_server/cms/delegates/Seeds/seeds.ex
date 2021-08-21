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

  # threads
  @lang_threads Seeds.Threads.get(:lang)

  @pl_communities Seeds.Communities.get(:pl)
  @framework_communities Seeds.Communities.get(:framework)
  @editor_communities Seeds.Communities.get(:editor)
  @database_communities Seeds.Communities.get(:database)
  @devops_communities Seeds.Communities.get(:devops)
  @city_communities Seeds.Communities.get(:city)
  # categories
  @default_categories Seeds.Categories.get(:default)

  @doc """
  seed communities pragraming languages
  """
  def seed_communities(:pl) do
    with {:ok, threads} <- seed_threads(:lang),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :pl) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)
      categorify_communities(communities, categories, :pl)
    end
  end

  @doc """
  seed communities for frameworks
  """
  def seed_communities(:framework) do
    with {:ok, threads} <- seed_threads(:lang),
         {:ok, bot} <- seed_bot(),
         {:ok, _categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :framework) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)

      # categorify_communities(communities, categories, :other)
    end
  end

  @doc """
  seed communities for editors
  """
  def seed_communities(:editor) do
    with {:ok, threads} <- seed_threads(:lang),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :editor) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)

      categorify_communities(communities, categories, :other)
    end
  end

  @doc """
  seed communities for database
  """
  def seed_communities(:database) do
    with {:ok, threads} <- seed_threads(:lang),
         {:ok, bot} <- seed_bot(),
         {:ok, _categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :database) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)

      # categorify_communities(communities, categories, :other)
    end
  end

  @doc """
  seed communities for database
  """
  def seed_communities(:devops) do
    with {:ok, threads} <- seed_threads(:lang),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :devops) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)

      categorify_communities(communities, categories, :other)
    end
  end

  @doc """
  seed communities for cities
  """
  def seed_communities(:city) do
    Seeds.Communities.get(:city)
    |> Enum.each(&seed_community(&1, :city))

    {:ok, :pass}
  end

  @doc """
  seed community for home
  """
  def seed_community(:home) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "home"}),
         {:ok, bot} <- seed_bot(),
         {:ok, threads} <- seed_threads(:home),
         {:ok, categories} <- seed_categories(bot, :default) do
      args = %{
        title: "coderplanets",
        desc: "the most sexy community for developers, ever.",
        logo: "#{@oss_endpoint}/icons/cmd/keyboard_logo.png",
        raw: "home",
        user_id: bot.id
      }

      {:ok, community} = Community |> ORM.create(args)

      threadify_communities(community, threads.entries)
      tagfy_threads(community, threads.entries, bot, :home)
      categorify_communities(community, categories, :other)
    end
  end

  # type: city, pl, framework, ...
  def seed_community(raw, type) do
    with {:ok, threads} <- seed_threads(type),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, community} <- insert_community(bot, raw, type) do
      threadify_communities([community], threads.entries)
      tagfy_threads([community], threads.entries, bot, type)
      categorify_communities([community], categories, type)

      {:ok, community}
    end
  end

  @doc """
  seed default threads like: post, user, wiki, cheetsheet, job ..
  """
  def seed_threads(:default) do
    case ORM.find_by(Thread, %{raw: "post"}) do
      {:ok, _} ->
        {:ok, :pass}

      {:error, _} ->
        @lang_threads
        |> Enum.each(fn thread ->
          {:ok, _thread} = CMS.create_thread(thread)
        end)
    end

    thread_titles =
      @lang_threads
      |> Enum.reduce([], fn x, acc -> acc ++ [x.title] end)

    Thread
    |> where([t], t.raw in ^thread_titles)
    |> ORM.paginator(page: 1, size: 30)
    |> done()
  end

  def seed_threads(:city), do: do_seed_threads(:city)
  def seed_threads(:home), do: do_seed_threads(:home)

  defp do_seed_threads(community) do
    threads = Seeds.Threads.get(community)
    threads_list = threads |> Enum.map(& &1.raw)

    with {:error, _} <- ORM.find_by(Thread, %{raw: "post"}) do
      threads |> Enum.each(&CMS.create_thread(&1))
    end

    Thread
    |> where([t], t.raw in ^threads_list)
    |> ORM.paginator(page: 1, size: 10)
    |> done()
  end

  def seed_categories(bot, :default) do
    case is_empty_db?(Category) do
      true ->
        Enum.each(@default_categories, fn cat ->
          CMS.create_category(cat, bot)
        end)

      false ->
        "pass"
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

  # seed raw communities, without thread or categories staff
  defp seed_for_communities(bot, :pl) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "javascript"}) do
      {:ok, _communities} = insert_multi_communities(bot, @pl_communities, :pl)
    end
  end

  defp seed_for_communities(bot, :framework) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "react"}) do
      {:ok, _communities} = insert_multi_communities(bot, @framework_communities, :framework)
    end
  end

  defp seed_for_communities(bot, :editor) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "emacs"}) do
      {:ok, _communities} = insert_multi_communities(bot, @editor_communities, :editor)
    end
  end

  defp seed_for_communities(bot, :database) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "mysql"}) do
      {:ok, _communities} = insert_multi_communities(bot, @database_communities, :database)
    end
  end

  defp seed_for_communities(bot, :devops) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "cps-support"}) do
      {:ok, _communities} = insert_multi_communities(bot, @devops_communities, :devops)
    end
  end

  defp seed_for_communities(bot, :city) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "chengdu"}) do
      {:ok, _communities} = insert_multi_communities(bot, @city_communities, :city)
    end
  end

  defp insert_multi_communities(bot, communities, type) do
    type = Atom.to_string(type)

    communities =
      Enum.reduce(communities, [], fn c, acc ->
        {:ok, community} = insert_community(bot, c, type)
        acc ++ [community]
      end)

    {:ok, communities}
  end

  defp insert_community(bot, raw, type) do
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

  # set threads to given communities
  defp threadify_communities(communities, threads) when is_list(communities) do
    Enum.each(communities, fn community ->
      Enum.each(threads, fn thread ->
        {:ok, _} = CMS.set_thread(%Community{id: community.id}, %Thread{id: thread.id})
      end)
    end)
  end

  defp threadify_communities(community, threads) do
    Enum.each(threads, fn thread ->
      # System.halt(0)
      {:ok, _} = CMS.set_thread(%Community{id: community.id}, %Thread{id: thread.id})
    end)
  end

  defp tagfy_threads(communities, _threads, bot, :city) when is_list(communities) do
    Enum.each(communities, fn community ->
      create_tags(community, :post, bot, :city)
    end)
  end

  defp tagfy_threads(community, threads, bot, :home) do
    threads
    |> Enum.each(&create_tags(community, &1, bot, :home))
  end

  defp tagfy_threads(communities, threads, bot) when is_list(communities) do
    Enum.each(communities, fn community ->
      Enum.each(threads, fn thread ->
        create_tags(community, thread, bot)
      end)
    end)
  end

  defp create_tags(%Community{} = community, %Thread{raw: raw}, bot) do
    thread = raw |> String.to_atom()

    Enum.each(Seeds.Tags.get(community, thread), fn attr ->
      CMS.create_article_tag(community, thread, attr, bot)
    end)
  end

  defp create_tags(%Community{} = community, :post, bot, :city) do
    Enum.each(Seeds.Tags.get(community, :post, :city), fn attr ->
      CMS.create_article_tag(community, :post, attr, bot)
    end)
  end

  defp create_tags(%Community{} = community, %Thread{raw: raw}, bot, :home) do
    thread = raw |> String.to_atom()

    Enum.each(Seeds.Tags.get(community, thread), fn attr ->
      CMS.create_article_tag(community, thread, attr, bot)
    end)
  end

  # set categories to given communities
  defp categorify_communities(communities, categories, part)
       when is_list(communities) and is_atom(part) do
    the_category = categories.entries |> Enum.find(fn cat -> cat.raw == Atom.to_string(part) end)

    Enum.each(communities, fn community ->
      {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: the_category.id})
    end)
  end

  defp categorify_communities(community, categories, part) when is_atom(part) do
    the_category = categories.entries |> Enum.find(fn cat -> cat.raw == Atom.to_string(part) end)

    {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: the_category.id})
  end

  # check is the seeds alreay runed
  defp is_empty_db?(queryable) do
    {:ok, results} = ORM.find_all(queryable, %{page: 1, size: 20})
    results.total_count == 0
  end
end
