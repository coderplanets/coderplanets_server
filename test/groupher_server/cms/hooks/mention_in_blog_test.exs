defmodule GroupherServer.Test.CMS.Hooks.MentionInBlog do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, blog} = db_insert(:blog)

    {:ok, community} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community blog blog_attrs)a}
  end

  describe "[mention in blog basic]" do
    test "mention multi user in blog should work", ~m(user user2 user3 community  blog_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>, and <div class=#{
            @article_mention_class
          }>#{user3.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      blog_attrs = blog_attrs |> Map.merge(%{body: body})
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, blog} = preload_author(blog)

      {:ok, _result} = Hooks.Mention.handle(blog)

      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "BLOG"
      assert mention.block_linker |> length == 2
      assert mention.article_id == blog.id
      assert mention.title == blog.title
      assert mention.user.login == blog.author.user.login

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "BLOG"
      assert mention.block_linker |> length == 1
      assert mention.article_id == blog.id
      assert mention.title == blog.title
      assert mention.user.login == blog.author.user.login
    end

    test "mention in blog's comment should work", ~m(user user2 blog)a do
      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>))

      {:ok, comment} = CMS.create_comment(:blog, blog.id, comment_body, user)
      {:ok, comment} = preload_author(comment)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "BLOG"
      assert mention.comment_id == comment.id
      assert mention.block_linker |> length == 1
      assert mention.article_id == blog.id
      assert mention.title == blog.title
      assert mention.user.login == comment.author.login
    end

    test "can not mention author self in blog or comment", ~m(community user blog_attrs)a do
      body = mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))
      blog_attrs = blog_attrs |> Map.merge(%{body: body})
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      assert result.total_count == 0

      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))

      {:ok, comment} = CMS.create_comment(:blog, blog.id, comment_body, user)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})

      assert result.total_count == 0
    end
  end
end
