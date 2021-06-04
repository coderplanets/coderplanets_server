defmodule GroupherServer.Test.CMS.Artilces.PostPin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)

    {:ok, ~m(user community post)a}
  end

  describe "[cms post pin]" do
    test "can pin a post", ~m(community post)a do
      {:ok, _} = CMS.pin_article(:post, post.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{post_id: post.id})

      assert pind_article.post_id == post.id
    end

    test "one community & thread can only pin certern count of post", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_post} = CMS.create_article(community, :post, mock_attrs(:post), user)
        {:ok, _} = CMS.pin_article(:post, new_post.id, community.id)
        acc
      end)

      {:ok, new_post} = CMS.create_article(community, :post, mock_attrs(:post), user)
      {:error, reason} = CMS.pin_article(:post, new_post.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit post", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:post, 8848, community.id)
    end

    test "can undo pin to a post", ~m(community post)a do
      {:ok, _} = CMS.pin_article(:post, post.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:post, post.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{post_id: post.id})
    end
  end
end
