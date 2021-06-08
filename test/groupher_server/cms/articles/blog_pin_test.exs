defmodule GroupherServer.Test.CMS.Artilces.BlogPin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)

    {:ok, ~m(user community blog)a}
  end

  describe "[cms blog pin]" do
    test "can pin a blog", ~m(community blog)a do
      {:ok, _} = CMS.pin_article(:blog, blog.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{blog_id: blog.id})

      assert pind_article.blog_id == blog.id
    end

    test "one community & thread can only pin certern count of blog", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)
        {:ok, _} = CMS.pin_article(:blog, new_blog.id, community.id)
        acc
      end)

      {:ok, new_blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)
      {:error, reason} = CMS.pin_article(:blog, new_blog.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit blog", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:blog, 8848, community.id)
    end

    test "can undo pin to a blog", ~m(community blog)a do
      {:ok, _} = CMS.pin_article(:blog, blog.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:blog, blog.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{blog_id: blog.id})
    end
  end
end
