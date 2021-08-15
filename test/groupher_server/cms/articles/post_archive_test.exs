defmodule GroupherServer.Test.CMS.PostArchive do
  @moduledoc false
  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.Post

  @now Timex.now()
  @archive_threshold get_config(:article, :archive_threshold)
  @post_archive_threshold Timex.shift(
                            @now,
                            @archive_threshold[:post] || @archive_threshold[:default]
                          )

  @last_week Timex.shift(@now, days: -7, seconds: -1)

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    {:ok, post_long_ago} = db_insert(:post, %{title: "last week", inserted_at: @last_week})
    db_insert_multi(:post, 5)

    {:ok, ~m(user community post_long_ago)a}
  end

  describe "[cms post archive]" do
    test "can archive posts", ~m(post_long_ago)a do
      {:ok, _} = CMS.archive_articles(:post)

      archived_posts =
        Post
        |> where([article], article.inserted_at < ^@post_archive_threshold)
        |> Repo.all()

      assert length(archived_posts) == 1
      archived_post = archived_posts |> List.first()
      assert archived_post.id == post_long_ago.id
    end

    test "can not edit archived post" do
      {:ok, _} = CMS.archive_articles(:post)

      archived_posts =
        Post
        |> where([article], article.inserted_at < ^@post_archive_threshold)
        |> Repo.all()

      archived_post = archived_posts |> List.first()
      {:error, reason} = CMS.update_article(archived_post, %{"title" => "new title"})
      assert reason |> is_error?(:archived)
    end

    test "can not delete archived post" do
      {:ok, _} = CMS.archive_articles(:post)

      archived_posts =
        Post
        |> where([article], article.inserted_at < ^@post_archive_threshold)
        |> Repo.all()

      archived_post = archived_posts |> List.first()

      {:error, reason} = CMS.mark_delete_article(:post, archived_post.id)
      assert reason |> is_error?(:archived)
    end
  end
end
