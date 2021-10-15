defmodule GroupherServer.CMS.Delegate.ArticleTag do
  @moduledoc """
  community curd
  """
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher
  import Helper.Validator.Guards, only: [g_is_id: 1]
  import Helper.Utils, only: [done: 1, atom_values_to_upcase: 1]
  import GroupherServer.CMS.Delegate.ArticleCURD, only: [ensure_author_exists: 1]
  import ShortMaps
  import Helper.ErrorCode

  alias Helper.ORM
  alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, Repo}

  alias Accounts.Model.User
  alias GroupherServer.CMS

  alias CMS.Model.{ArticleTag, Community}
  alias CMS.Delegate.CommunityCURD

  alias Ecto.Multi

  @doc """
  create a article tag
  """
  def create_article_tag(%Community{} = community, thread, attrs, %User{id: user_id}) do
    with {:ok, author} <- ensure_author_exists(%User{id: user_id}),
         {:ok, community} <- ORM.find(Community, community.id) do
      Multi.new()
      |> Multi.run(:create_article_tag, fn _, _ ->
        update_attrs = %{author_id: author.id, community_id: community.id, thread: thread}
        attrs = attrs |> Map.merge(update_attrs) |> atom_values_to_upcase

        ORM.create(ArticleTag, attrs)
      end)
      |> Multi.run(:update_community_count, fn _, _ ->
        CommunityCURD.update_community_count_field(community, :article_tags_count)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  update an article tag
  """
  def update_article_tag(id, attrs) do
    with {:ok, article_tag} <- ORM.find(ArticleTag, id) do
      attrs = attrs |> atom_values_to_upcase
      ORM.update(article_tag, attrs)
    end
  end

  @doc """
  delete an article tag
  """
  def delete_article_tag(id) do
    with {:ok, article_tag} <- ORM.find(ArticleTag, id),
         {:ok, community} <- ORM.find(Community, article_tag.community_id) do
      Multi.new()
      |> Multi.run(:delete_article_tag, fn _, _ ->
        ORM.delete(article_tag)
      end)
      |> Multi.run(:update_community_count, fn _, _ ->
        CommunityCURD.update_community_count_field(community, :article_tags_count)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  # check if the tag to be set is in same community & thread
  defp is_article_tag_in_some_thread?(article_tag_ids, filter) do
    with {:ok, paged_article_tags} <- paged_article_tags(filter) do
      domain_tags_ids = Enum.map(paged_article_tags.entries, &to_string(&1.id))
      article_tag_ids = Enum.map(article_tag_ids, &to_string(&1))

      Enum.all?(article_tag_ids, &Enum.member?(domain_tags_ids, &1))
    else
      _ -> false
    end
  end

  @doc """
  set article tag by list of article_tag_ids

  used for create article with article_tags in args
  """
  def set_article_tags(_, _, article, %{article_tags: []}), do: {:ok, article}

  def set_article_tags(%Community{id: cid}, thread, article, %{article_tags: article_tag_ids}) do
    check_filter = %{page: 1, size: 100, community_id: cid, thread: thread}

    with true <- is_article_tag_in_some_thread?(article_tag_ids, check_filter),
         Enum.each(article_tag_ids, &set_article_tag(thread, article, &1)) |> done do
      {:ok, article}
    else
      false -> raise_error(:invalid_domain_tag, "tag not in same community & thread")
    end
  end

  def set_article_tags(_community, _thread, article, _), do: {:ok, article}

  @doc """
  set article a tag
  """
  def set_article_tag(thread, article_id, tag_id) when g_is_id(article_id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: :article_tags),
         {:ok, article_tag} <- ORM.find(ArticleTag, tag_id) do
      do_update_article_tags_assoc(article, article_tag, :add)
    end
  end

  def set_article_tag(_thread, article, tag_id) do
    article = Repo.preload(article, :article_tags)

    with {:ok, article_tag} <- ORM.find(ArticleTag, tag_id) do
      do_update_article_tags_assoc(article, article_tag, :add)
    end
  end

  @doc """
  unset article a tag
  """
  def unset_article_tag(thread, article_id, tag_id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: :article_tags),
         {:ok, article_tag} <- ORM.find(ArticleTag, tag_id) do
      do_update_article_tags_assoc(article, article_tag, :remove)
    end
  end

  defp do_update_article_tags_assoc(article, %ArticleTag{} = tag, opt) do
    article_tags =
      case opt do
        :add -> (article.article_tags ++ [tag]) |> Enum.uniq_by(& &1.id)
        :remove -> article.article_tags -- [tag]
      end

    article
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:article_tags, article_tags)
    |> Repo.update()
  end

  @doc """
  get all paged tags
  """
  def paged_article_tags(%{page: page, size: size} = filter) do
    ArticleTag
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginator(~m(page size)a)
    |> done()
  end

  # if no page info given, load 100 tags by default
  def paged_article_tags(filter) do
    ArticleTag
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginator(%{page: 1, size: 100})
    |> done()
  end

  defp result({:ok, %{create_article_tag: result}}), do: {:ok, result}
  defp result({:ok, %{delete_article_tag: result}}), do: {:ok, result}
  defp result({:error, _, result, _steps}), do: {:error, result}
end
