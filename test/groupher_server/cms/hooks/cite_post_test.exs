defmodule GroupherServer.Test.CMS.Hooks.CitePost do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Post, Comment, CitedArtiment}
  alias CMS.Delegate.Hooks

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

  describe "[cite basic]" do
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

      Hooks.Cite.handle(post)
      Hooks.Cite.handle(post_n)

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

      Hooks.Cite.handle(post)

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

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite post's comment in post", ~m(community user post post2 post_attrs)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(~s(the <a href=#{@site_host}/post/#{post2.id}?comment_id=#{comment.id} />))

      post_attrs = post_attrs |> Map.merge(%{body: body})

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      Hooks.Cite.handle(post)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: comment.id})

      # 被 post 以 comment link 的方式引用了
      assert cited_content.post_id == post.id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user post)a do
      {:ok, cited_comment} = CMS.create_comment(:post, post.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/post/#{post.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:post, post.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: cited_comment.id})
      assert comment.id == cited_content.comment_id
      assert cited_comment.id == cited_content.cited_by_id
      assert cited_content.cited_by_type == "COMMENT"
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
      Hooks.Cite.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/post/#{post3.id} />))
      {:ok, comment} = CMS.create_comment(:post, post.id, comment_body, user)

      Hooks.Cite.handle(comment)

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

  describe "[cite pagi]" do
    test "can get paged cited articles.", ~m(user community post2 post_attrs)a do
      {:ok, comment} =
        CMS.create_comment(
          :post,
          post2.id,
          mock_comment(~s(the <a href=#{@site_host}/post/#{post2.id} />)),
          user
        )

      Process.sleep(1000)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/post/#{post2.id} />),
          ~s(the <a href=#{@site_host}/post/#{post2.id} />)
        )

      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post_x} = CMS.create_article(community, :post, post_attrs, user)

      Process.sleep(1000)
      body = mock_rich_text(~s(the <a href=#{@site_host}/post/#{post2.id} />))
      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post_y} = CMS.create_article(community, :post, post_attrs, user)

      Hooks.Cite.handle(post_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(post_y)

      {:ok, result} = CMS.paged_citing_contents("POST", post2.id, %{page: 1, size: 10})

      entries = result.entries

      result_comment = entries |> List.first()
      result_post_x = entries |> Enum.at(1)
      result_post_y = entries |> List.last()

      article_map_keys = [:block_linker, :id, :inserted_at, :thread, :title, :user]

      assert result_comment.comment_id == comment.id
      assert result_comment.id == post2.id
      assert result_comment.title == post2.title

      assert result_post_x.id == post_x.id
      assert result_post_x.block_linker |> length == 2
      assert result_post_x |> Map.keys() == article_map_keys

      assert result_post_y.id == post_y.id
      assert result_post_y.block_linker |> length == 1
      assert result_post_y |> Map.keys() == article_map_keys

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 3
    end
  end

  describe "[cross cite]" do
    test "can citing multi type thread and comment in one time", ~m(user community post2)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id})
      job_attrs = mock_attrs(:job, %{community_id: community.id})
      blog_attrs = mock_attrs(:blog, %{community_id: community.id})

      body = mock_rich_text(~s(the <a href=#{@site_host}/post/#{post2.id} />))

      {:ok, post} =
        CMS.create_article(community, :post, Map.merge(post_attrs, %{body: body}), user)

      Hooks.Cite.handle(post)

      Process.sleep(1000)

      {:ok, job} = CMS.create_article(community, :job, Map.merge(job_attrs, %{body: body}), user)
      Hooks.Cite.handle(job)

      Process.sleep(1000)

      comment_body = mock_comment(~s(the <a href=#{@site_host}/post/#{post2.id} />))
      {:ok, comment} = CMS.create_comment(:job, job.id, comment_body, user)

      Hooks.Cite.handle(comment)

      Process.sleep(1000)

      {:ok, blog} =
        CMS.create_article(community, :blog, Map.merge(blog_attrs, %{body: body}), user)

      Hooks.Cite.handle(blog)

      {:ok, result} = CMS.paged_citing_contents("POST", post2.id, %{page: 1, size: 10})
      # IO.inspect(result, label: "the result")

      assert result.total_count == 4

      result_post = result.entries |> List.first()
      result_job = result.entries |> Enum.at(1)
      result_comment = result.entries |> Enum.at(2)
      result_blog = result.entries |> List.last()

      assert result_post.id == post.id
      assert result_post.thread == :post

      assert result_job.id == job.id
      assert result_job.thread == :job

      assert result_comment.id == job.id
      assert result_comment.thread == :job
      assert result_comment.comment_id == comment.id

      assert result_blog.id == blog.id
      assert result_blog.thread == :blog
    end
  end
end
