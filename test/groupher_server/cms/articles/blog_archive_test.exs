defmodule GroupherServer.Test.CMS.BlogArchive do
  @moduledoc false
  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.Blog

  @now Timex.now()
  @archive_threshold get_config(:article, :archive_threshold)
  @blog_archive_threshold Timex.shift(
                            @now,
                            @archive_threshold[:blog] || @archive_threshold[:default]
                          )

  @last_week Timex.shift(@now, days: -7, seconds: -1)

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, blog} = db_insert(:blog)
    {:ok, community} = db_insert(:community)

    {:ok, blog_long_ago} = db_insert(:blog, %{title: "last week", inserted_at: @last_week})
    db_insert_multi(:blog, 5)

    {:ok, ~m(user community blog_long_ago)a}
  end

  describe "[cms blog archive]" do
    test "can archive blogs", ~m(blog_long_ago)a do
      {:ok, _} = CMS.archive_articles(:blog)

      archived_blogs =
        Blog
        |> where([article], article.inserted_at < ^@blog_archive_threshold)
        |> Repo.all()

      assert length(archived_blogs) == 1
      archived_blog = archived_blogs |> List.first()
      assert archived_blog.id == blog_long_ago.id
    end

    test "can not edit archived blog" do
      {:ok, _} = CMS.archive_articles(:blog)

      archived_blogs =
        Blog
        |> where([article], article.inserted_at < ^@blog_archive_threshold)
        |> Repo.all()

      archived_blog = archived_blogs |> List.first()
      {:error, reason} = CMS.update_article(archived_blog, %{"title" => "new title"})
      assert reason |> is_error?(:archived)
    end

    test "can not delete archived blog" do
      {:ok, _} = CMS.archive_articles(:blog)

      archived_blogs =
        Blog
        |> where([article], article.inserted_at < ^@blog_archive_threshold)
        |> Repo.all()

      archived_blog = archived_blogs |> List.first()

      {:error, reason} = CMS.mark_delete_article(:blog, archived_blog.id)
      assert reason |> is_error?(:archived)
    end
  end
end
