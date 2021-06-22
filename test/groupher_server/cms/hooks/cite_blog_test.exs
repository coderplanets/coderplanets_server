defmodule GroupherServer.Test.CMS.Hooks.CiteBlog do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Blog, Comment, CitedArtiment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, blog} = db_insert(:blog)
    {:ok, blog2} = db_insert(:blog)
    {:ok, blog3} = db_insert(:blog)
    {:ok, blog4} = db_insert(:blog)
    {:ok, blog5} = db_insert(:blog)

    {:ok, community} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})

    {:ok, ~m(user user2 community blog blog2 blog3 blog4 blog5 blog_attrs)a}
  end

  describe "[cite basic]" do
    test "cited multi blog should work", ~m(user community blog2 blog3 blog4 blog5 blog_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/blog/#{blog2.id} /> and <a href=#{@site_host}/blog/#{
            blog2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/blog/#{blog3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/blog/#{blog2.id} class=#{blog2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/blog/#{blog4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/blog/#{blog5.id}> again</a>)
        )

      blog_attrs = blog_attrs |> Map.merge(%{body: body})
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/blog/#{blog3.id} />))
      blog_attrs = blog_attrs |> Map.merge(%{body: body})
      {:ok, blog_n} = CMS.create_article(community, :blog, blog_attrs, user)

      Hooks.Cite.handle(blog)
      Hooks.Cite.handle(blog_n)

      {:ok, blog2} = ORM.find(Blog, blog2.id)
      {:ok, blog3} = ORM.find(Blog, blog3.id)
      {:ok, blog4} = ORM.find(Blog, blog4.id)
      {:ok, blog5} = ORM.find(Blog, blog5.id)

      assert blog2.meta.citing_count == 1
      assert blog3.meta.citing_count == 2
      assert blog4.meta.citing_count == 1
      assert blog5.meta.citing_count == 1
    end

    test "cited blog itself should not work", ~m(user community blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/blog/#{blog.id} />))
      {:ok, blog} = CMS.update_article(blog, %{body: body})

      Hooks.Cite.handle(blog)

      {:ok, blog} = ORM.find(Blog, blog.id)
      assert blog.meta.citing_count == 0
    end

    test "cited comment itself should not work", ~m(user blog)a do
      {:ok, cited_comment} = CMS.create_comment(:blog, blog.id, mock_rich_text("hello"), user)

      {:ok, comment} =
        CMS.update_comment(
          cited_comment,
          mock_comment(
            ~s(the <a href=#{@site_host}/blog/#{blog.id}?comment_id=#{cited_comment.id} />)
          )
        )

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite blog's comment in blog", ~m(community user blog blog2 blog_attrs)a do
      {:ok, comment} = CMS.create_comment(:blog, blog.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(~s(the <a href=#{@site_host}/blog/#{blog2.id}?comment_id=#{comment.id} />))

      blog_attrs = blog_attrs |> Map.merge(%{body: body})

      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      Hooks.Cite.handle(blog)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: comment.id})

      # 被 blog 以 comment link 的方式引用了
      assert cited_content.blog_id == blog.id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user blog)a do
      {:ok, cited_comment} = CMS.create_comment(:blog, blog.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/blog/#{blog.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:blog, blog.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: cited_comment.id})
      assert comment.id == cited_content.comment_id
      assert cited_comment.id == cited_content.cited_by_id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cited blog inside a comment", ~m(user blog blog2 blog3 blog4 blog5)a do
      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/blog/#{blog2.id} /> and <a href=#{@site_host}/blog/#{
            blog2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/blog/#{blog3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/blog/#{blog2.id} class=#{blog2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/blog/#{blog4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/blog/#{blog5.id}> again</a>)
        )

      {:ok, comment} = CMS.create_comment(:blog, blog.id, comment_body, user)
      Hooks.Cite.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/blog/#{blog3.id} />))
      {:ok, comment} = CMS.create_comment(:blog, blog.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, blog2} = ORM.find(Blog, blog2.id)
      {:ok, blog3} = ORM.find(Blog, blog3.id)
      {:ok, blog4} = ORM.find(Blog, blog4.id)
      {:ok, blog5} = ORM.find(Blog, blog5.id)

      assert blog2.meta.citing_count == 1
      assert blog3.meta.citing_count == 2
      assert blog4.meta.citing_count == 1
      assert blog5.meta.citing_count == 1
    end
  end

  describe "[cite pagi]" do
    test "can get paged cited articles.", ~m(user community blog2 blog_attrs)a do
      {:ok, comment} =
        CMS.create_comment(
          :blog,
          blog2.id,
          mock_comment(~s(the <a href=#{@site_host}/blog/#{blog2.id} />)),
          user
        )

      Process.sleep(1000)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/blog/#{blog2.id} />),
          ~s(the <a href=#{@site_host}/blog/#{blog2.id} />)
        )

      blog_attrs = blog_attrs |> Map.merge(%{body: body})
      {:ok, blog_x} = CMS.create_article(community, :blog, blog_attrs, user)

      Process.sleep(1000)
      body = mock_rich_text(~s(the <a href=#{@site_host}/blog/#{blog2.id} />))
      blog_attrs = blog_attrs |> Map.merge(%{body: body})
      {:ok, blog_y} = CMS.create_article(community, :blog, blog_attrs, user)

      Hooks.Cite.handle(blog_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(blog_y)

      {:ok, result} = CMS.paged_citing_contents("BLOG", blog2.id, %{page: 1, size: 10})

      entries = result.entries

      result_comment = entries |> List.first()
      result_blog_x = entries |> Enum.at(1)
      result_blog_y = entries |> List.last()

      article_map_keys = [:block_linker, :id, :inserted_at, :thread, :title, :user]

      assert result_comment.comment_id == comment.id
      assert result_comment.id == blog2.id
      assert result_comment.title == blog2.title

      assert result_blog_x.id == blog_x.id
      assert result_blog_x.block_linker |> length == 2
      assert result_blog_x |> Map.keys() == article_map_keys

      assert result_blog_y.id == blog_y.id
      assert result_blog_y.block_linker |> length == 1
      assert result_blog_y |> Map.keys() == article_map_keys

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 3
    end
  end
end
