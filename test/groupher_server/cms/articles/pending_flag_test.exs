defmodule GroupherServer.Test.CMS.PostPendingFlag do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS, Repo}
  alias Accounts.Model.User
  alias Helper.ORM

  @total_count 35

  @audit_legal CMS.Constant.pending(:legal)
  @audit_illegal CMS.Constant.pending(:illegal)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, community2} = db_insert(:community)
    CMS.create_article(community2, :post, mock_attrs(:post), user)

    posts =
      Enum.reduce(1..@total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_article(community, :post, mock_attrs(:post), user)
        acc ++ [value]
      end)

    post_b = posts |> List.first()
    post_m = posts |> Enum.at(div(@total_count, 2))
    post_e = posts |> List.last()

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user post_b post_m post_e)a}
  end

  describe "[pending posts flags]" do
    test "pending post can not be read", ~m(post_m)a do
      {:ok, _} = CMS.read_article(:post, post_m.id)

      {:ok, _} =
        CMS.set_article_illegal(:post, post_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, post_m} = ORM.find(CMS.Model.Post, post_m.id)
      assert post_m.pending == @audit_illegal

      {:error, reason} = CMS.read_article(:post, post_m.id)
      assert reason |> is_error?(:pending)
    end

    test "author can read it's own pending post", ~m(community user)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, _} = CMS.read_article(:post, post.id)

      {:ok, _} =
        CMS.set_article_illegal(:post, post.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, post_read} = CMS.read_article(:post, post.id, user)
      assert post_read.id == post.id

      {:ok, user2} = db_insert(:user)
      {:error, reason} = CMS.read_article(:post, post.id, user2)
      assert reason |> is_error?(:pending)
    end

    test "pending post can set/unset pending", ~m(post_m)a do
      {:ok, _} = CMS.read_article(:post, post_m.id)

      {:ok, _} =
        CMS.set_article_illegal(:post, post_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, post_m} = ORM.find(CMS.Model.Post, post_m.id)
      assert post_m.pending == @audit_illegal

      {:ok, _} = CMS.unset_article_illegal(:post, post_m.id, %{})

      {:ok, post_m} = ORM.find(CMS.Model.Post, post_m.id)
      assert post_m.pending == @audit_legal

      {:ok, _} = CMS.read_article(:post, post_m.id)
    end

    test "pending post's meta should have info", ~m(post_m)a do
      {:ok, _} = CMS.read_article(:post, post_m.id)

      {:ok, _} =
        CMS.set_article_illegal(:post, post_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"],
          illegal_articles: ["/post/#{post_m.id}"]
        })

      {:ok, post_m} = ORM.find(CMS.Model.Post, post_m.id)
      assert post_m.pending == @audit_illegal
      assert not post_m.meta.is_legal
      assert post_m.meta.illegal_reason == ["some-reason"]
      assert post_m.meta.illegal_words == ["some-word"]

      post_m = Repo.preload(post_m, :author)
      {:ok, user} = ORM.find(User, post_m.author.user_id)
      assert user.meta.has_illegal_articles
      assert user.meta.illegal_articles == ["/post/#{post_m.id}"]

      {:ok, _} =
        CMS.unset_article_illegal(:post, post_m.id, %{
          is_legal: true,
          illegal_reason: [],
          illegal_words: [],
          illegal_articles: ["/post/#{post_m.id}"]
        })

      {:ok, post_m} = ORM.find(CMS.Model.Post, post_m.id)
      assert post_m.pending == @audit_legal
      assert post_m.meta.is_legal
      assert post_m.meta.illegal_reason == []
      assert post_m.meta.illegal_words == []

      post_m = Repo.preload(post_m, :author)
      {:ok, user} = ORM.find(User, post_m.author.user_id)
      assert not user.meta.has_illegal_articles
      assert user.meta.illegal_articles == []
    end
  end

  alias CMS.Delegate.Hooks

  # test "can audit paged audit failed posts", ~m(post_m)a do
  #   {:ok, post} = ORM.find(CMS.Model.Post, post_m.id)

  #   {:ok, post} = CMS.set_article_audit_failed(post, %{})

  #   {:ok, result} = CMS.paged_audit_failed_articles(:post, %{page: 1, size: 20})
  #   assert result |> is_valid_pagination?(:raw)
  #   assert result.total_count == 1

  #   Enum.map(result.entries, fn post ->
  #     Hooks.Audition.handle(post)
  #   end)

  #   {:ok, result} = CMS.paged_audit_failed_articles(:post, %{page: 1, size: 20})
  #   assert result.total_count == 0
  # end
end
