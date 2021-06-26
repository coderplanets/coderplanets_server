defmodule GroupherServer.Test.CMS.Hooks.MentionInDrink do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, drink} = db_insert(:drink)

    {:ok, community} = db_insert(:community)

    drink_attrs = mock_attrs(:drink, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community drink drink_attrs)a}
  end

  describe "[mention in drink basic]" do
    test "mention multi user in drink should work",
         ~m(user user2 user3 community  drink_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>, and <div class=#{
            @article_mention_class
          }>#{user3.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      drink_attrs = drink_attrs |> Map.merge(%{body: body})
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, drink} = preload_author(drink)

      {:ok, _result} = Hooks.Mention.handle(drink)

      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "DRINK"
      assert mention.block_linker |> length == 2
      assert mention.article_id == drink.id
      assert mention.title == drink.title
      assert mention.user.login == drink.author.user.login

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "DRINK"
      assert mention.block_linker |> length == 1
      assert mention.article_id == drink.id
      assert mention.title == drink.title
      assert mention.user.login == drink.author.user.login
    end

    test "mention in drink's comment should work", ~m(user user2 drink)a do
      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>))

      {:ok, comment} = CMS.create_comment(:drink, drink.id, comment_body, user)
      {:ok, comment} = preload_author(comment)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "DRINK"
      assert mention.comment_id == comment.id
      assert mention.block_linker |> length == 1
      assert mention.article_id == drink.id
      assert mention.title == drink.title
      assert mention.user.login == comment.author.login
    end

    test "can not mention author self in drink or comment", ~m(community user drink_attrs)a do
      body = mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))
      drink_attrs = drink_attrs |> Map.merge(%{body: body})
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      assert result.total_count == 0

      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))

      {:ok, comment} = CMS.create_comment(:drink, drink.id, comment_body, user)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})

      assert result.total_count == 0
    end
  end
end
