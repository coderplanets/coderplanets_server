defmodule GroupherServer.Test.CMS.Hooks.NotifyBlog do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})
    {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
    {:ok, comment} = CMS.create_comment(:blog, blog.id, mock_comment(), user)

    {:ok, ~m(user2 blog comment)a}
  end

  describe "[upvote notify]" do
    @tag :wip2
    test "upvote hook should work on blog", ~m(user2 blog)a do
      {:ok, blog} = preload_author(blog)

      {:ok, article} = CMS.upvote_article(:blog, blog.id, user2)
      Hooks.Notify.handle(:upvote, article, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, blog.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "UPVOTE"
      assert notify.article_id == blog.id
      assert notify.type == "BLOG"
      assert notify.user_id == blog.author.user.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip2
    test "upvote hook should work on blog comment", ~m(user2 blog comment)a do
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)
      {:ok, comment} = preload_author(comment)

      Hooks.Notify.handle(:upvote, comment, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, comment.author.id, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "UPVOTE"
      assert notify.article_id == blog.id
      assert notify.type == "COMMENT"
      assert notify.user_id == comment.author.id
      assert notify.comment_id == comment.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip2
    test "undo upvote hook should work on blog", ~m(user2 blog)a do
      {:ok, blog} = preload_author(blog)

      {:ok, article} = CMS.upvote_article(:blog, blog.id, user2)
      Hooks.Notify.handle(:upvote, article, user2)

      {:ok, article} = CMS.undo_upvote_article(:blog, blog.id, user2)
      Hooks.Notify.handle(:undo, :upvote, article, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, blog.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end

    @tag :wip2
    test "undo upvote hook should work on blog comment", ~m(user2 comment)a do
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)

      Hooks.Notify.handle(:upvote, comment, user2)

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user2)
      Hooks.Notify.handle(:undo, :upvote, comment, user2)

      {:ok, comment} = preload_author(comment)

      {:ok, notifications} =
        Delivery.fetch(:notification, comment.author.id, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end
  end

  describe "[collect notify]" do
    @tag :wip
    test "collect hook should work on blog", ~m(user2 blog)a do
      {:ok, blog} = preload_author(blog)

      {:ok, _} = CMS.collect_article(:blog, blog.id, user2)
      Hooks.Notify.handle(:collect, blog, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, blog.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "COLLECT"
      assert notify.article_id == blog.id
      assert notify.type == "BLOG"
      assert notify.user_id == blog.author.user.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip
    test "undo collect hook should work on blog", ~m(user2 blog)a do
      {:ok, blog} = preload_author(blog)

      {:ok, _} = CMS.upvote_article(:blog, blog.id, user2)
      Hooks.Notify.handle(:collect, blog, user2)

      {:ok, _} = CMS.undo_upvote_article(:blog, blog.id, user2)
      Hooks.Notify.handle(:undo, :collect, blog, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, blog.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end
  end
end
