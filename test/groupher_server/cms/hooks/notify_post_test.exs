defmodule GroupherServer.Test.CMS.Hooks.NotifyPost do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}

  # alias CMS.Model.{Comment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})
    {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

    {:ok, ~m(user2 post)a}
  end

  describe "[upvote notify]" do
    @tag :wip
    test "upvote hook should work", ~m(user2 post)a do
      {:ok, post} = preload_author(post)

      {:ok, article} = CMS.upvote_article(:post, post.id, user2)
      Hooks.Notify.handle(:upvote, article, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, post.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.article_id == post.id
      assert notify.type == "POST"
      assert notify.user_id == post.author.user.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip
    test "undo upvote hook should work", ~m(user2 post)a do
      {:ok, post} = preload_author(post)

      {:ok, article} = CMS.upvote_article(:post, post.id, user2)
      Hooks.Notify.handle(:upvote, article, user2)

      {:ok, article} = CMS.undo_upvote_article(:post, post.id, user2)
      Hooks.Notify.handle(:undo, :upvote, article, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, post.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end
  end
end
