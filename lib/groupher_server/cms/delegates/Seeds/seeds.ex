defmodule GroupherServer.CMS.Delegate.Seeds do
  @moduledoc """
  seeds data for init, should be called ONLY in new database, like migration
  """

  import GroupherServer.Support.Factory
  import Helper.Utils, only: [done: 1]
  import Ecto.Query, warn: false

  import GroupherServer.CMS.Delegate.Seeds.Helper,
    only: [
      threadify_communities: 2,
      tagfy_threads: 4,
      categorify_communities: 3,
      seed_bot: 0,
      seed_threads: 1,
      seed_categories_ifneed: 1,
      insert_community: 3
    ]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, Category, Post}
  alias CMS.Delegate.Seeds
  alias Seeds.Domain

  # categories
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
  def seed_community(:home), do: Domain.seed_community(:home)
  def seed_community(:blackhole), do: Domain.seed_community(:blackhole)
  def seed_community(:feedback), do: Domain.seed_community(:feedback)

  # type: city, pl, framework, ...
  def seed_community(raw, type) when type in @community_types do
    with {:ok, threads} <- seed_threads(type),
         {:ok, bot} <- seed_bot(),
         {:ok, categories} <- seed_categories_ifneed(bot),
         {:ok, community} <- insert_community(bot, raw, type) do
      threadify_communities([community], threads.entries)
      tagfy_threads([community], threads.entries, bot, type)
      categorify_communities([community], categories, type)

      {:ok, community}
    end
  end

  def seed_community(_raw, _type), do: "undown community type"

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

  def seed_articles(%Community{} = community, :post, count \\ 3) do
    with {:ok, community} <- ORM.find(Community, community.id) do
      {:ok, user} = db_insert(:user)

      1..count
      |> Enum.each(fn _ ->
        post_attrs = mock_attrs(:post, %{community_id: community.id})
        CMS.create_article(community, :post, post_attrs, user)
      end)
    end
  end

  def seed_posts(:other_articles) do
  end

  # clean up

  def clean_up(:all) do
    #
  end

  def clean_up_community(raw) do
    with {:ok, community} <- ORM.findby_delete(Community, %{raw: to_string(raw)}) do
      clean_up_articles(community, :post)
    end
  end

  def clean_up_articles(%Community{} = community, :post) do
    Post
    |> join(:inner, [p], c in assoc(p, :original_community))
    |> where([p, c], c.id == ^community.id)
    |> ORM.delete_all(:if_exist)
    |> done
  end

  def clean_up_articles(_, _), do: {:ok, :pass}
end
