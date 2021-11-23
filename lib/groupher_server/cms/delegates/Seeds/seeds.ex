defmodule GroupherServer.CMS.Delegate.Seeds do
  @moduledoc """
  seeds data for init, should be called ONLY in new database, like migration
  """

  import GroupherServer.Support.Factory
  import Helper.Utils, only: [done: 1, get_config: 2]
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

  alias CMS.Model.{Community, Category, Post, Comment}
  alias CMS.Delegate.Seeds
  alias Seeds.Domain

  @article_threads get_config(:article, :threads)
  # categories
  @community_types [:pl, :framework, :editor, :database, :devops, :city]

  @comment_emotions get_config(:article, :comment_emotions)
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

  def seed_articles(%Community{} = community, thread, count \\ 3)
      when thread in @article_threads do
    #
    thread_upcase = thread |> to_string |> String.upcase()
    tags_filter = %{community_id: community.id, thread: thread_upcase}

    with {:ok, community} <- ORM.find(Community, community.id),
         {:ok, tags} <- CMS.paged_article_tags(tags_filter),
         {:ok, user} <- db_insert(:user) do
      1..count
      |> Enum.each(fn _ ->
        attrs = mock_attrs(thread, %{community_id: community.id})
        {:ok, article} = CMS.create_article(community, thread, attrs, user)
        seed_tags(tags, thread, article.id)
        seed_comments(thread, article.id, user)
        seed_upvotes(thread, article.id)
      end)
    end
  end

  defp seed_upvotes(thread, article_id) do
    with {:ok, users} <- db_insert_multi(:user, Enum.random(1..10)) do
      users
      |> Enum.each(fn user ->
        {:ok, _article} = CMS.upvote_article(thread, article_id, user)
      end)
    end
  end

  defp seed_tags(tags, thread, article_id) do
    get_tag_ids(tags, thread)
    |> Enum.each(fn tag_id ->
      {:ok, _} = CMS.set_article_tag(thread, article_id, tag_id)
    end)
  end

  defp get_tag_ids(tags, :job) do
    tags.entries |> Enum.map(& &1.id) |> Enum.shuffle() |> Enum.take(3)
  end

  defp get_tag_ids(tags, _) do
    tags.entries |> Enum.map(& &1.id) |> Enum.shuffle() |> Enum.take(1)
  end

  defp seed_comments(thread, article_id, user) do
    0..Enum.random(1..5)
    |> Enum.each(fn _ ->
      text = Faker.Lorem.sentence(20)
      {:ok, comment} = CMS.create_comment(thread, article_id, mock_comment(text), user)
      seed_comment_emotions(comment)
      seed_comment_replies(comment)
    end)
  end

  defp seed_comment_replies(%Comment{} = comment) do
    with {:ok, users} <- db_insert_multi(:user, Enum.random(1..5)) do
      users
      |> Enum.each(fn user ->
        text = Faker.Lorem.sentence(20)
        {:ok, _} = CMS.reply_comment(comment.id, mock_comment(text), user)
      end)
    end
  end

  defp seed_comment_emotions(%Comment{} = comment) do
    with {:ok, users} <- db_insert_multi(:user, Enum.random(1..5)) do
      users
      |> Enum.each(fn user ->
        emotion = @comment_emotions |> Enum.random()
        {:ok, _} = CMS.emotion_to_comment(comment.id, emotion, user)
      end)
    end
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
