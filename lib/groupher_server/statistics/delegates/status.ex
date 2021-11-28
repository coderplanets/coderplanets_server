defmodule GroupherServer.Statistics.Delegate.Status do
  @moduledoc """
  badic count info of the whole site, used in admin panel sidebar
  """

  import Ecto.Query, warn: false
  import ShortMaps

  alias GroupherServer.CMS

  alias CMS.Model.{
    Post,
    Job,
    Guide,
    Meetup,
    Drink,
    Blog,
    Radar,
    Works,
    Drink,
    Community,
    Thread,
    Category,
    ArticleTag
  }

  alias Helper.{ORM, Cache}

  @cache_pool :online_status
  @count_filter %{page: 1, size: 1}

  def online_status() do
    with {:ok, realtime_visitors} <- Cache.get(@cache_pool, :realtime_visitors) do
      {:ok, %{realtime_visitors: realtime_visitors}}
    else
      _ ->
        {:ok, %{realtime_visitors: 1}}
    end
  end

  def count_status do
    {:ok, %{total_count: communities_count}} = find_total_count(Community)
    {:ok, %{total_count: posts_count}} = find_total_count(Post)
    {:ok, %{total_count: jobs_count}} = find_total_count(Job)
    {:ok, %{total_count: blogs_count}} = find_total_count(Blog)
    {:ok, %{total_count: works_count}} = find_total_count(Works)
    {:ok, %{total_count: meetups_count}} = find_total_count(Meetup)
    {:ok, %{total_count: guides_count}} = find_total_count(Guide)
    {:ok, %{total_count: radars_count}} = find_total_count(Radar)
    {:ok, %{total_count: drinks_count}} = find_total_count(Drink)

    {:ok, %{total_count: threads_count}} = find_total_count(Thread)
    {:ok, %{total_count: article_tags_count}} = find_total_count(ArticleTag)
    {:ok, %{total_count: categories_count}} = find_total_count(Category)

    {:ok,
     ~m(communities_count posts_count jobs_count works_count meetups_count guides_count radars_count blogs_count drinks_count threads_count article_tags_count categories_count)a}
  end

  defp find_total_count(queryable), do: ORM.find_all(queryable, @count_filter)
end
