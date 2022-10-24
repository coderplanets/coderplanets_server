defmodule GroupherServer.Test.CMS.Hooks.AuditPost do
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

    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user community post post_attrs)a}
  end

  describe "[audit post basic]" do
    # test "ugly words shoud get audit", ~m(user community  post_attrs)a do
    #   body = mock_rich_text("M卖批, 这也太操蛋了, 党中央")

    #   post_attrs = post_attrs |> Map.merge(%{body: body})
    #   {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

    #   Hooks.Audition.handle(post)

    #   {:ok, post} = ORM.find(CMS.Model.Post, post.id)

    #   assert post.pending == @audit_illegal
    #   assert post.meta.is_legal == false
    #   assert post.meta.illegal_reason == ["政治敏感", "低俗辱骂"]
    #   assert post.meta.illegal_words == ["党中央", "操蛋", "卖批"]
    # end

    # test "normal words shoud not get audit", ~m(user community  post_attrs)a do
    #   body = mock_rich_text("世界属于三体")

    #   post_attrs = post_attrs |> Map.merge(%{body: body})
    #   {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

    #   Hooks.Audition.handle(post)

    #   {:ok, post} = ORM.find(CMS.Model.Post, post.id)

    #   assert post.pending == @audit_legal
    #   assert post.meta.is_legal == true
    #   assert post.meta.illegal_reason == []
    #   assert post.meta.illegal_words == []
    # end

    # test "failed audit should have falied state", ~m(user community  post_attrs)a do
    #   body = mock_rich_text("世界属于三体")

    #   post_attrs = post_attrs |> Map.merge(%{body: body})
    #   {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

    #   Hooks.Audition.handle_edge(post)

    #   {:ok, post} = ORM.find(CMS.Model.Post, post.id)
    #   assert post.pending == @audit_failed
    # end
  end
end
