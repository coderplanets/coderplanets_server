defmodule GroupherServer.Test.CMS.Hooks.MentionInMeetup do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, meetup} = db_insert(:meetup)

    {:ok, community} = db_insert(:community)

    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community meetup meetup_attrs)a}
  end

  describe "[mention in meetup basic]" do
    test "mention multi user in meetup should work",
         ~m(user user2 user3 community  meetup_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>, and <div class=#{
            @article_mention_class
          }>#{user3.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      meetup_attrs = meetup_attrs |> Map.merge(%{body: body})
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, meetup} = preload_author(meetup)

      {:ok, _result} = Hooks.Mention.handle(meetup)

      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "MEETUP"
      assert mention.block_linker |> length == 2
      assert mention.article_id == meetup.id
      assert mention.title == meetup.title
      assert mention.user.login == meetup.author.user.login

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "MEETUP"
      assert mention.block_linker |> length == 1
      assert mention.article_id == meetup.id
      assert mention.title == meetup.title
      assert mention.user.login == meetup.author.user.login
    end

    test "mention in meetup's comment should work", ~m(user user2 meetup)a do
      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>))

      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, comment_body, user)
      {:ok, comment} = preload_author(comment)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "MEETUP"
      assert mention.comment_id == comment.id
      assert mention.block_linker |> length == 1
      assert mention.article_id == meetup.id
      assert mention.title == meetup.title
      assert mention.user.login == comment.author.login
    end

    test "can not mention author self in meetup or comment", ~m(community user meetup_attrs)a do
      body = mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))
      meetup_attrs = meetup_attrs |> Map.merge(%{body: body})
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      assert result.total_count == 0

      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))

      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, comment_body, user)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})

      assert result.total_count == 0
    end
  end
end
