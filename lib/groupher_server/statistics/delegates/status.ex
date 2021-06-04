defmodule GroupherServer.Statistics.Delegate.Status do
  @moduledoc """
  badic count info of the whole site, used in admin panel sidebar
  """

  import Ecto.Query, warn: false
  import ShortMaps

  alias GroupherServer.CMS
  alias CMS.Model.{Post, Job, Repo, Community, Thread, Category, ArticleTag}
  alias Helper.ORM

  @count_filter %{page: 1, size: 1}

  def count_status do
    {:ok, %{total_count: communities_count}} = find_total_count(Community)
    {:ok, %{total_count: posts_count}} = find_total_count(Post)
    {:ok, %{total_count: jobs_count}} = find_total_count(Job)
    {:ok, %{total_count: repos_count}} = find_total_count(Repo)

    {:ok, %{total_count: threads_count}} = find_total_count(Thread)
    {:ok, %{total_count: article_tags_count}} = find_total_count(ArticleTag)
    {:ok, %{total_count: categories_count}} = find_total_count(Category)

    {:ok,
     ~m(communities_count posts_count jobs_count repos_count threads_count article_tags_count categories_count)a}
  end

  defp find_total_count(queryable), do: ORM.find_all(queryable, @count_filter)
end
