defmodule GroupherServer.Test.CMS.Hooks.MentionInGuide do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, guide} = db_insert(:guide)

    {:ok, community} = db_insert(:community)

    guide_attrs = mock_attrs(:guide, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community guide guide_attrs)a}
  end

  describe "[mention in guide basic]" do
    test "mention multi user in guide should work",
         ~m(user user2 user3 community  guide_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>, and <div class=#{
            @article_mention_class
          }>#{user3.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      guide_attrs = guide_attrs |> Map.merge(%{body: body})
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, guide} = preload_author(guide)

      {:ok, _result} = Hooks.Mention.handle(guide)

      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "GUIDE"
      assert mention.block_linker |> length == 2
      assert mention.article_id == guide.id
      assert mention.title == guide.title
      assert mention.user.login == guide.author.user.login

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "GUIDE"
      assert mention.block_linker |> length == 1
      assert mention.article_id == guide.id
      assert mention.title == guide.title
      assert mention.user.login == guide.author.user.login
    end

    test "mention in guide's comment should work", ~m(user user2 guide)a do
      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>))

      {:ok, comment} = CMS.create_comment(:guide, guide.id, comment_body, user)
      {:ok, comment} = preload_author(comment)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "GUIDE"
      assert mention.comment_id == comment.id
      assert mention.block_linker |> length == 1
      assert mention.article_id == guide.id
      assert mention.title == guide.title
      assert mention.user.login == comment.author.login
    end

    test "can not mention author self in guide or comment", ~m(community user guide_attrs)a do
      body = mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))
      guide_attrs = guide_attrs |> Map.merge(%{body: body})
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      assert result.total_count == 0

      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))

      {:ok, comment} = CMS.create_comment(:guide, guide.id, comment_body, user)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})

      assert result.total_count == 0
    end
  end
end
