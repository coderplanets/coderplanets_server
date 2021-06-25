defmodule GroupherServer.Test.CMS.Hooks.MentionInWorks do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, works} = db_insert(:works)

    {:ok, community} = db_insert(:community)

    works_attrs = mock_attrs(:works, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community works works_attrs)a}
  end

  describe "[mention in works basic]" do
    test "mention multi user in works should work",
         ~m(user user2 user3 community  works_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>, and <div class=#{
            @article_mention_class
          }>#{user3.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      works_attrs = works_attrs |> Map.merge(%{body: body})
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, works} = preload_author(works)

      {:ok, _result} = Hooks.Mention.handle(works)

      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "WORKS"
      assert mention.block_linker |> length == 2
      assert mention.article_id == works.id
      assert mention.title == works.title
      assert mention.user.login == works.author.user.login

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "WORKS"
      assert mention.block_linker |> length == 1
      assert mention.article_id == works.id
      assert mention.title == works.title
      assert mention.user.login == works.author.user.login
    end

    test "mention in works's comment should work", ~m(user user2 works)a do
      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>))

      {:ok, comment} = CMS.create_comment(:works, works.id, comment_body, user)
      {:ok, comment} = preload_author(comment)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "WORKS"
      assert mention.comment_id == comment.id
      assert mention.block_linker |> length == 1
      assert mention.article_id == works.id
      assert mention.title == works.title
      assert mention.user.login == comment.author.login
    end

    test "can not mention author self in works or comment", ~m(community user works_attrs)a do
      body = mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))
      works_attrs = works_attrs |> Map.merge(%{body: body})
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      assert result.total_count == 0

      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))

      {:ok, comment} = CMS.create_comment(:works, works.id, comment_body, user)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})

      assert result.total_count == 0
    end
  end
end
