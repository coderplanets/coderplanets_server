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
  alias GroupherServer.CMS.Model.{Community, Thread, Category}

  alias CMS.Delegate.SeedsConfig

  # threads
  @default_threads SeedsConfig.threads(:default)
  @city_threads SeedsConfig.threads(:city, :list)
  @home_threads SeedsConfig.threads(:home, :list)

  # communities
  # done
  @pl_patch_communities SeedsConfig.communities(:pl_patch)
  @framework_patch_communities SeedsConfig.communities(:framework_patch)
  @pl_communities SeedsConfig.communities(:pl)
  @framework_communities SeedsConfig.communities(:framework)
  @ui_communities SeedsConfig.communities(:ui)
  @editor_communities SeedsConfig.communities(:editor)
  @database_communities SeedsConfig.communities(:database)
  @devops_communities SeedsConfig.communities(:devops)
  @dblockchain_communities SeedsConfig.communities(:blockchain)
  # done
  @city_communities SeedsConfig.communities(:city)

  # categories
  @default_categories SeedsConfig.categories(:default)

  @doc """
  seed communities for pl_patch
  """
  def seed_communities(:pl_patch) do
    with {:ok, threads} <- seed_threads(:default),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :pl_patch) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)
      categorify_communities(communities, categories, :pl)
    end
  end

  @doc """
  seed communities for pl_patch
  """
  def seed_communities(:framework_patch) do
    with {:ok, threads} <- seed_threads(:default),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :framework_patch) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)
      categorify_communities(communities, categories, :ai)
    end
  end

  @doc """
  seed communities pragraming languages
  """
  def seed_communities(:pl) do
    with {:ok, threads} <- seed_threads(:default),
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
    with {:ok, threads} <- seed_threads(:default),
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
    with {:ok, threads} <- seed_threads(:default),
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
    with {:ok, threads} <- seed_threads(:default),
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
    with {:ok, threads} <- seed_threads(:default),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :devops) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)

      categorify_communities(communities, categories, :other)
    end
  end

  @doc """
  seed communities for database
  """
  def seed_communities(:blockchain) do
    with {:ok, threads} <- seed_threads(:default),
         {:ok, bot} <- seed_bot(),
         {:ok, _categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :blockchain) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)

      # categorify_communities(communities, categories, :other)
    end
  end

  @doc """
  seed communities for designs
  """
  def seed_communities(:ui) do
    with {:ok, threads} <- seed_threads(:default),
         {:ok, bot} <- seed_bot(),
         {:ok, _categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :ui) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot)

      # categorify_communities(communities, categories, :other)
    end
  end

  @doc """
  seed communities for cities
  """
  def seed_communities(:city) do
    with {:ok, threads} <- seed_threads(:city),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories(bot, :default),
         {:ok, communities} <- seed_for_communities(bot, :city) do
      threadify_communities(communities, threads.entries)
      tagfy_threads(communities, threads.entries, bot, :city)
      categorify_communities(communities, categories, :city)
    end
  end

  @doc """
  seed community for home
  """
  def seed_communities(:home) do
    with {:error, _} <- ORM.find_by(CMS.Community, %{raw: "home"}),
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

  @doc """
  seed default threads like: post, user, wiki, cheetsheet, job ..
  """
  def seed_threads(:default) do
    case ORM.find_by(CMS.Thread, %{raw: "post"}) do
      {:ok, _} ->
        {:ok, :pass}

      {:error, _} ->
        @default_threads
        |> Enum.each(fn thread ->
          {:ok, _thread} = CMS.create_thread(thread)
        end)
    end

    thread_titles =
      @default_threads
      |> Enum.reduce([], fn x, acc -> acc ++ [x.title] end)

    CMS.Thread
    |> where([t], t.raw in ^thread_titles)
    |> ORM.paginater(page: 1, size: 30)
    |> done()
  end

  def seed_threads(:city) do
    case ORM.find_by(CMS.Thread, %{raw: "post"}) do
      {:ok, _} -> {:ok, :pass}
      {:error, _} -> seed_threads(:default)
    end

    {:ok, _thread} = CMS.create_thread(%{title: "group", raw: "group", index: 1})
    {:ok, _thread} = CMS.create_thread(%{title: "company", raw: "company", index: 2})

    CMS.Thread
    |> where([t], t.raw in @city_threads)
    |> ORM.paginater(page: 1, size: 10)
    |> done()
  end

  # NOTE: the home threads should be insert after default threads
  def seed_threads(:home) do
    case ORM.find_by(CMS.Thread, %{raw: "post"}) do
      {:ok, _} -> {:ok, :pass}
      {:error, _} -> seed_threads(:default)
    end

    {:ok, _thread} = CMS.create_thread(%{title: "tech", raw: "tech", index: 1})
    {:ok, _thread} = CMS.create_thread(%{title: "radar", raw: "radar", index: 2})
    {:ok, _thread} = CMS.create_thread(%{title: "share", raw: "share", index: 3})
    {:ok, _thread} = CMS.create_thread(%{title: "city", raw: "city", index: 16})

    CMS.Thread
    |> where([t], t.raw in @home_threads)
    |> ORM.paginater(page: 1, size: 10)
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
    case ORM.find(Accounts.User, 1) do
      {:ok, user} ->
        {:ok, user}

      {:error, _} ->
        nickname = "cps_bot_2398614_2018"
        avatar = "https://avatars1.githubusercontent.com/u/6184465?s=460&v=4"

        Accounts.User |> ORM.findby_or_insert(~m(nickname avatar)a, ~m(nickname avatar)a)
        # Accounts.User |> ORM.create(~m(nickname avatar)a)
    end
  end

  # manual pl patch missing community
  defp seed_for_communities(bot, :pl_patch) do
    {:ok, _communities} = insert_multi_communities(bot, @pl_patch_communities, :pl)
  end

  # manual framework patch missing community
  defp seed_for_communities(bot, :framework_patch) do
    {:ok, _communities} = insert_multi_communities(bot, @framework_patch_communities, :framework)
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

  defp seed_for_communities(bot, :blockchain) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "bitcoin"}) do
      {:ok, _communities} = insert_multi_communities(bot, @dblockchain_communities, :blockchain)
    end
  end

  defp seed_for_communities(bot, :ui) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "css"}) do
      {:ok, _communities} = insert_multi_communities(bot, @ui_communities, :ui)
    end
  end

  defp seed_for_communities(bot, :city) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "chengdu"}) do
      {:ok, _communities} = insert_multi_communities(bot, @city_communities, :city)
    end
  end

  defp svg_icons do
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

  defp insert_multi_communities(bot, communities, type) do
    type = Atom.to_string(type)

    communities =
      Enum.reduce(communities, [], fn c, acc ->
        ext = if Enum.member?(svg_icons(), c), do: "svg", else: "png"

        args = %{
          title: trans(c),
          aka: c,
          desc: "#{c} is awesome!",
          logo: "#{@oss_endpoint}/icons/#{type}/#{c}.#{ext}",
          raw: c,
          user_id: bot.id
        }

        {:ok, community} = ORM.create(Community, args)

        acc ++ [community]
      end)

    {:ok, communities}
  end

  defp trans("beijing"), do: "北京"
  defp trans("shanghai"), do: "上海"
  defp trans("shenzhen"), do: "深圳"
  defp trans("hangzhou"), do: "杭州"
  defp trans("guangzhou"), do: "广州"
  defp trans("chengdu"), do: "成都"
  defp trans("wuhan"), do: "武汉"
  defp trans("xiamen"), do: "厦门"
  defp trans("nanjing"), do: "南京"
  defp trans(c), do: c

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

  defp tagfy_threads(communities, threads, bot) when is_list(communities) do
    Enum.each(communities, fn community ->
      Enum.each(threads, fn thread ->
        create_tags(community, thread, bot)
      end)
    end)
  end

  defp tagfy_threads(community, threads, bot, :home) do
    Enum.each(threads, fn thread ->
      create_tags(community, thread, bot, :home)
    end)
  end

  defp create_tags(%Community{} = community, %Thread{raw: raw}, bot) do
    thread = raw |> String.to_atom()

    Enum.each(SeedsConfig.tags(thread), fn attr ->
      CMS.create_tag(community, thread, attr, bot)
    end)
  end

  defp create_tags(%Community{} = community, :post, bot, :city) do
    Enum.each(SeedsConfig.tags(:city, :post), fn attr ->
      CMS.create_tag(community, :post, attr, bot)
    end)
  end

  defp create_tags(%Community{} = community, %Thread{raw: raw}, bot, :home) do
    thread = raw |> String.to_atom()

    Enum.each(SeedsConfig.tags(:home, thread), fn attr ->
      CMS.create_tag(community, thread, attr, bot)
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
