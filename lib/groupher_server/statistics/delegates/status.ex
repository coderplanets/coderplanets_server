defmodule GroupherServer.Statistics.Delegate.Status do
  @moduledoc """
  badic count info of the whole site, used in admin panel sidebar
  """

  import Ecto.Query, warn: false
  import ShortMaps

  # alias GroupherServer.Repo
  # alias GroupherServer.Accounts.User
  alias GroupherServer.CMS
  # alias GroupherServer.Statistics.{UserContribute, CommunityContribute}
  alias Helper.ORM

  @count_filter %{page: 1, size: 1}

  def count_status do
    {:ok, %{total_count: communities_count}} = find_total_count(CMS.Community)
    {:ok, %{total_count: posts_count}} = find_total_count(CMS.Post)
    {:ok, %{total_count: jobs_count}} = find_total_count(CMS.Job)
    {:ok, %{total_count: videos_count}} = find_total_count(CMS.Video)
    {:ok, %{total_count: repos_count}} = find_total_count(CMS.Repo)

    {:ok, %{total_count: threads_count}} = find_total_count(CMS.Thread)
    {:ok, %{total_count: tags_count}} = find_total_count(CMS.Tag)
    {:ok, %{total_count: categories_count}} = find_total_count(CMS.Category)

    {:ok,
     ~m(communities_count posts_count jobs_count videos_count repos_count threads_count tags_count categories_count)a}
  end

  defp find_total_count(queryable), do: ORM.find_all(queryable, @count_filter)
end
