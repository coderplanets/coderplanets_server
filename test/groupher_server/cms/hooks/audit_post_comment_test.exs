defmodule GroupherServer.Test.CMS.Hooks.AuditPostComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.{CMS}
  alias CMS.Delegate.Hooks
  alias Helper.{ORM, Scheduler}
  alias CMS.Constant

  @audit_legal Constant.pending(:legal)
  @audit_illegal Constant.pending(:illegal)
  @audit_failed Constant.pending(:audit_failed)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)

    {:ok, ~m(user post)a}
  end

  describe "[audit post basic]" do
    # test "ugly words shoud get audit", ~m(user post)a do
    #   {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment("M卖批, 这也太操蛋了, 党中央"), user)

    #   Hooks.Audition.handle(comment)
    #   {:ok, comment} = ORM.find(CMS.Model.Comment, comment.id)

    #   assert comment.pending == @audit_illegal
    #   assert comment.meta.is_legal == false
    #   assert comment.meta.illegal_reason == ["政治敏感", "低俗辱骂"]
    #   assert comment.meta.illegal_words == ["党中央", "操蛋", "卖批"]
    # end

    # test "normal words shoud not get audit", ~m(user post)a do
    #   {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment("世界属于三体"), user)

    #   Hooks.Audition.handle(comment)
    #   {:ok, comment} = ORM.find(CMS.Model.Comment, comment.id)

    #   assert comment.pending == @audit_legal
    #   assert comment.meta.is_legal == true
    #   assert comment.meta.illegal_reason == []
    #   assert comment.meta.illegal_words == []
    # end

    # test "failed audit should have falied state", ~m(user post)a do
    #   {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment("世界属于三体"), user)

    #   Hooks.Audition.handle_edge(comment)

    #   {:ok, comment} = ORM.find(CMS.Model.Comment, comment.id)
    #   assert comment.pending == @audit_failed
    # end

    # test "can handle paged audit failed comments", ~m(user post)a do
    #   {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment("世界属于三体"), user)
    #   CMS.set_article_audit_failed(comment, %{})

    #   {:ok, paged_comments} = CMS.paged_audit_failed_comments(%{page: 1, size: 30})
    #   assert paged_comments |> is_valid_pagination?(:raw)
    #   assert paged_comments.total_count == 1

    #   Enum.map(paged_comments.entries, fn comment ->
    #     Hooks.Audition.handle(comment)
    #   end)

    #   {:ok, paged_comments} = CMS.paged_audit_failed_comments(%{page: 1, size: 30})
    #   assert paged_comments.total_count == 0
    # end

    # test "can handle paged audit failed comments from Scheduler" do
    #   {:ok, _results} = Scheduler.comments_audition()
    # end
  end
end
