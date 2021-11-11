defmodule GroupherServer.Test.CMS.Hooks.AuditPostComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.{CMS}
  alias CMS.Delegate.Hooks
  alias Helper.ORM
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
    @tag :wip
    test "ugly words shoud get audit", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment("M卖批, 这也太操蛋了, 党中央"), user)

      Hooks.Audition.handle(comment)
      {:ok, comment} = ORM.find(CMS.Model.Comment, comment.id)

      assert comment.pending == @audit_illegal
      assert comment.meta.is_legal == false
      assert comment.meta.illegal_reason == ["政治敏感", "低俗辱骂"]
      assert comment.meta.illegal_words == ["党中央", "操蛋", "卖批"]
    end

    @tag :wip
    test "normal words shoud not get audit", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment("世界属于三体"), user)

      Hooks.Audition.handle(comment)
      {:ok, comment} = ORM.find(CMS.Model.Comment, comment.id)

      assert comment.pending == @audit_legal
      assert comment.meta.is_legal == true
      assert comment.meta.illegal_reason == []
      assert comment.meta.illegal_words == []
    end

    @tag :wip
    test "failed audit should have falied state", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment("世界属于三体"), user)

      Hooks.Audition.handle_edge(comment)

      {:ok, comment} = ORM.find(CMS.Model.Comment, comment.id)
      assert comment.pending == @audit_failed
    end
  end
end
