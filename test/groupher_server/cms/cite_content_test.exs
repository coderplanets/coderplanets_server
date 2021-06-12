defmodule GroupherServer.Test.CMS.CiteContent do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS
  alias Helper.Converter.{EditorToHTML, HtmlSanitizer, Converter}

  alias EditorToHTML.{Class, Validator}
  alias CMS.Model.{Author, Community, Post}

  alias CMS.Delegate.BlockTasks

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
    @tag :wip
    test "basic", ~m(user community post2 post3 post4 post5 post_attrs)a do
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
      BlockTasks.handle(post)

      {:ok, post2} = ORM.find(Post, post2.id)
      {:ok, post3} = ORM.find(Post, post3.id)
      {:ok, post4} = ORM.find(Post, post4.id)

      assert post2.meta.citing_count == 1
      assert post3.meta.citing_count == 1
      assert post4.meta.citing_count == 1
    end
  end
end
