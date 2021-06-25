defmodule GroupherServer.Test.CMS.Hooks.CiteWorks do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Works, Comment, CitedArtiment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, works} = db_insert(:works)
    {:ok, works2} = db_insert(:works)
    {:ok, works3} = db_insert(:works)
    {:ok, works4} = db_insert(:works)
    {:ok, works5} = db_insert(:works)

    {:ok, community} = db_insert(:community)

    works_attrs = mock_attrs(:works, %{community_id: community.id})

    {:ok, ~m(user user2 community works works2 works3 works4 works5 works_attrs)a}
  end

  describe "[cite basic]" do
    test "cited multi works should work",
         ~m(user community works2 works3 works4 works5 works_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/works/#{works2.id} /> and <a href=#{@site_host}/works/#{
            works2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/works/#{works3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/works/#{works2.id} class=#{works2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/works/#{works4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/works/#{
            works5.id
          }> again</a>)
        )

      works_attrs = works_attrs |> Map.merge(%{body: body})
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/works/#{works3.id} />))
      works_attrs = works_attrs |> Map.merge(%{body: body})
      {:ok, works_n} = CMS.create_article(community, :works, works_attrs, user)

      Hooks.Cite.handle(works)
      Hooks.Cite.handle(works_n)

      {:ok, works2} = ORM.find(Works, works2.id)
      {:ok, works3} = ORM.find(Works, works3.id)
      {:ok, works4} = ORM.find(Works, works4.id)
      {:ok, works5} = ORM.find(Works, works5.id)

      assert works2.meta.citing_count == 1
      assert works3.meta.citing_count == 2
      assert works4.meta.citing_count == 1
      assert works5.meta.citing_count == 1
    end

    test "cited works itself should not work", ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/works/#{works.id} />))
      {:ok, works} = CMS.update_article(works, %{body: body})

      Hooks.Cite.handle(works)

      {:ok, works} = ORM.find(Works, works.id)
      assert works.meta.citing_count == 0
    end

    test "cited comment itself should not work", ~m(user works)a do
      {:ok, cited_comment} = CMS.create_comment(:works, works.id, mock_rich_text("hello"), user)

      {:ok, comment} =
        CMS.update_comment(
          cited_comment,
          mock_comment(
            ~s(the <a href=#{@site_host}/works/#{works.id}?comment_id=#{cited_comment.id} />)
          )
        )

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite works's comment in works", ~m(community user works works2 works_attrs)a do
      {:ok, comment} = CMS.create_comment(:works, works.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/works/#{works2.id}?comment_id=#{comment.id} />)
        )

      works_attrs = works_attrs |> Map.merge(%{body: body})

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      Hooks.Cite.handle(works)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: comment.id})

      # 被 works 以 comment link 的方式引用了
      assert cited_content.works_id == works.id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user works)a do
      {:ok, cited_comment} = CMS.create_comment(:works, works.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/works/#{works.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:works, works.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: cited_comment.id})
      assert comment.id == cited_content.comment_id
      assert cited_comment.id == cited_content.cited_by_id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cited works inside a comment", ~m(user works works2 works3 works4 works5)a do
      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/works/#{works2.id} /> and <a href=#{@site_host}/works/#{
            works2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/works/#{works3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/works/#{works2.id} class=#{works2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/works/#{works4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/works/#{
            works5.id
          }> again</a>)
        )

      {:ok, comment} = CMS.create_comment(:works, works.id, comment_body, user)
      Hooks.Cite.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/works/#{works3.id} />))
      {:ok, comment} = CMS.create_comment(:works, works.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, works2} = ORM.find(Works, works2.id)
      {:ok, works3} = ORM.find(Works, works3.id)
      {:ok, works4} = ORM.find(Works, works4.id)
      {:ok, works5} = ORM.find(Works, works5.id)

      assert works2.meta.citing_count == 1
      assert works3.meta.citing_count == 2
      assert works4.meta.citing_count == 1
      assert works5.meta.citing_count == 1
    end
  end

  describe "[cite pagi]" do
    test "can get paged cited articles.", ~m(user community works2 works_attrs)a do
      {:ok, comment} =
        CMS.create_comment(
          :works,
          works2.id,
          mock_comment(~s(the <a href=#{@site_host}/works/#{works2.id} />)),
          user
        )

      Process.sleep(1000)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/works/#{works2.id} />),
          ~s(the <a href=#{@site_host}/works/#{works2.id} />)
        )

      works_attrs = works_attrs |> Map.merge(%{body: body})
      {:ok, works_x} = CMS.create_article(community, :works, works_attrs, user)

      Process.sleep(1000)
      body = mock_rich_text(~s(the <a href=#{@site_host}/works/#{works2.id} />))
      works_attrs = works_attrs |> Map.merge(%{body: body})
      {:ok, works_y} = CMS.create_article(community, :works, works_attrs, user)

      Hooks.Cite.handle(works_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(works_y)

      {:ok, result} = CMS.paged_citing_contents("WORKS", works2.id, %{page: 1, size: 10})

      entries = result.entries

      result_comment = entries |> List.first()
      result_works_x = entries |> Enum.at(1)
      result_works_y = entries |> List.last()

      article_map_keys = [:block_linker, :id, :inserted_at, :thread, :title, :user]

      assert result_comment.comment_id == comment.id
      assert result_comment.id == works2.id
      assert result_comment.title == works2.title

      assert result_works_x.id == works_x.id
      assert result_works_x.block_linker |> length == 2
      assert result_works_x |> Map.keys() == article_map_keys

      assert result_works_y.id == works_y.id
      assert result_works_y.block_linker |> length == 1
      assert result_works_y |> Map.keys() == article_map_keys

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 3
    end
  end
end
