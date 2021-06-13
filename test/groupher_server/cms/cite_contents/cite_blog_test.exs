defmodule GroupherServer.Test.CMS.CiteContent.Blog do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.Blog

  alias CMS.Delegate.CiteTasks

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
    @tag :wip
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

      CiteTasks.handle(blog)
      CiteTasks.handle(blog_n)

      {:ok, blog2} = ORM.find(Blog, blog2.id)
      {:ok, blog3} = ORM.find(Blog, blog3.id)
      {:ok, blog4} = ORM.find(Blog, blog4.id)
      {:ok, blog5} = ORM.find(Blog, blog5.id)

      assert blog2.meta.citing_count == 1
      assert blog3.meta.citing_count == 2
      assert blog4.meta.citing_count == 1
      assert blog5.meta.citing_count == 1
    end

    @tag :wip
    test "cited blog itself should not work", ~m(user community blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/blog/#{blog.id} />))
      {:ok, blog} = CMS.update_article(blog, %{body: body})

      CiteTasks.handle(blog)

      {:ok, blog} = ORM.find(Blog, blog.id)
      assert blog.meta.citing_count == 0
    end
  end
end
