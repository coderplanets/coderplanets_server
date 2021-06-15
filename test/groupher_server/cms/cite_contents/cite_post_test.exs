defmodule GroupherServer.Test.CMS.CiteContent.Post do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Post, Comment, CitedContent}
  alias CMS.Delegate.CiteTasks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, post2} = db_insert(:post)
    {:ok, post3} = db_insert(:post)
    {:ok, post4} = db_insert(:post)
    {:ok, post5} = db_insert(:post)

    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community post post2 post3 post4 post5 post_attrs)a}
  end

  describe "[cite pagi]" do
    @tag :wip
    test "--can get paged cited articles.", ~m(user community post2 post_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/post/#{post2.id} />),
          ~s(the <a href=#{@site_host}/post/#{post2.id} />)
        )

      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post_x} = CMS.create_article(community, :post, post_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/post/#{post2.id} />))
      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post_y} = CMS.create_article(community, :post, post_attrs, user)

      CiteTasks.handle(post_x)
      CiteTasks.handle(post_y)

      CMS.paged_citing_contents(post2.id, %{page: 1, size: 10})
    end
  end

  describe "[cite basic]" do
    #
    test "cited multi post should work", ~m(user community post2 post3 post4 post5 post_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/post/#{post2.id} /> and <a href=#{@site_host}/post/#{
            post2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/post/#{post3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/post/#{post2.id} class=#{post2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/post/#{post4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/post/#{post5.id}> again</a>)
        )

      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/post/#{post3.id} />))
      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post_n} = CMS.create_article(community, :post, post_attrs, user)

      CiteTasks.handle(post)
      CiteTasks.handle(post_n)

      {:ok, post2} = ORM.find(Post, post2.id)
      {:ok, post3} = ORM.find(Post, post3.id)
      {:ok, post4} = ORM.find(Post, post4.id)
      {:ok, post5} = ORM.find(Post, post5.id)

      assert post2.meta.citing_count == 1
      assert post3.meta.citing_count == 2
      assert post4.meta.citing_count == 1
      assert post5.meta.citing_count == 1
    end

    test "cited post itself should not work", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/post/#{post.id} />))
      {:ok, post} = CMS.update_article(post, %{body: body})

      CiteTasks.handle(post)

      {:ok, post} = ORM.find(Post, post.id)
      assert post.meta.citing_count == 0
    end

    test "cited comment itself should not work", ~m(user post)a do
      {:ok, cited_comment} = CMS.create_comment(:post, post.id, mock_rich_text("hello"), user)

      {:ok, comment} =
        CMS.update_comment(
          cited_comment,
          mock_comment(
            ~s(the <a href=#{@site_host}/post/#{post.id}?comment_id=#{cited_comment.id} />)
          )
        )

      CiteTasks.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite post's comment in post", ~m(community user post post2 post_attrs)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(~s(the <a href=#{@site_host}/post/#{post2.id}?comment_id=#{comment.id} />))

      post_attrs = post_attrs |> Map.merge(%{body: body})

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      CiteTasks.handle(post)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cite_content} = ORM.find_by(CitedContent, %{cited_by_id: comment.id})
      assert post.id == cite_content.post_id
      assert cite_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user post)a do
      {:ok, cited_comment} = CMS.create_comment(:post, post.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/post/#{post.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:post, post.id, comment_body, user)

      CiteTasks.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cite_content} = ORM.find_by(CitedContent, %{cited_by_id: cited_comment.id})
      assert comment.id == cite_content.comment_id
      assert cited_comment.id == cite_content.cited_by_id
      assert cite_content.cited_by_type == "COMMENT"
    end

    test "can cited post inside a comment", ~m(user post post2 post3 post4 post5)a do
      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/post/#{post2.id} /> and <a href=#{@site_host}/post/#{
            post2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/post/#{post3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/post/#{post2.id} class=#{post2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/post/#{post4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/post/#{post5.id}> again</a>)
        )

      {:ok, comment} = CMS.create_comment(:post, post.id, comment_body, user)
      CiteTasks.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/post/#{post3.id} />))
      {:ok, comment} = CMS.create_comment(:post, post.id, comment_body, user)

      CiteTasks.handle(comment)

      {:ok, post2} = ORM.find(Post, post2.id)
      {:ok, post3} = ORM.find(Post, post3.id)
      {:ok, post4} = ORM.find(Post, post4.id)
      {:ok, post5} = ORM.find(Post, post5.id)

      assert post2.meta.citing_count == 1
      assert post3.meta.citing_count == 2
      assert post4.meta.citing_count == 1
      assert post5.meta.citing_count == 1
    end
  end
end
