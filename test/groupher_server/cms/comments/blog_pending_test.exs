defmodule GroupherServer.Test.CMS.Comments.BlogPending do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias CMS.Model.Comment
  alias Helper.ORM
  alias CMS.Constant

  @audit_legal Constant.pending(:legal)
  @audit_illegal Constant.pending(:illegal)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, blog} = db_insert(:blog)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user blog)a}
  end

  describe "[pending blog comemnt flags]" do
    test "pending blog comment can set/unset pending", ~m(blog user)a do
      {:ok, comment} = CMS.create_comment(:blog, blog.id, mock_comment(), user)

      {:ok, _} =
        CMS.set_comment_illegal(comment.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.pending == @audit_illegal

      {:ok, _} =
        CMS.unset_comment_illegal(comment.id, %{
          is_legal: true,
          illegal_reason: [],
          illegal_words: []
        })

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.pending == @audit_legal
    end

    test "pending blog-comment's meta should have info", ~m(blog user)a do
      {:ok, comment} = CMS.create_comment(:blog, blog.id, mock_comment(), user)

      {:ok, _} =
        CMS.set_comment_illegal(comment.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"],
          illegal_comments: ["/blog/#{blog.id}/comment/#{comment.id}"]
        })

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.pending == @audit_illegal
      assert not comment.meta.is_legal
      assert comment.meta.illegal_reason == ["some-reason"]
      assert comment.meta.illegal_words == ["some-word"]

      {:ok, user} = ORM.find(User, comment.author_id)
      assert user.meta.has_illegal_comments
      assert user.meta.illegal_comments == ["/blog/#{blog.id}/comment/#{comment.id}"]

      {:ok, _} =
        CMS.unset_comment_illegal(comment.id, %{
          is_legal: true,
          illegal_reason: [],
          illegal_words: [],
          illegal_comments: ["/blog/#{blog.id}/comment/#{comment.id}"]
        })

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.pending == @audit_legal
      assert comment.meta.is_legal
      assert comment.meta.illegal_reason == []
      assert comment.meta.illegal_words == []

      {:ok, user} = ORM.find(User, comment.author_id)
      assert not user.meta.has_illegal_comments
      assert user.meta.illegal_comments == []
    end
  end
end
