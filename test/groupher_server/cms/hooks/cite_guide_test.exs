defmodule GroupherServer.Test.CMS.Hooks.CiteGuide do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Guide, Comment, CitedArtiment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, guide} = db_insert(:guide)
    {:ok, guide2} = db_insert(:guide)
    {:ok, guide3} = db_insert(:guide)
    {:ok, guide4} = db_insert(:guide)
    {:ok, guide5} = db_insert(:guide)

    {:ok, community} = db_insert(:community)

    guide_attrs = mock_attrs(:guide, %{community_id: community.id})

    {:ok, ~m(user user2 community guide guide2 guide3 guide4 guide5 guide_attrs)a}
  end

  describe "[cite basic]" do
    test "cited multi guide should work",
         ~m(user community guide2 guide3 guide4 guide5 guide_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/guide/#{guide2.id} /> and <a href=#{@site_host}/guide/#{
            guide2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/guide/#{guide3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/guide/#{guide2.id} class=#{guide2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/guide/#{guide4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/guide/#{
            guide5.id
          }> again</a>)
        )

      guide_attrs = guide_attrs |> Map.merge(%{body: body})
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/guide/#{guide3.id} />))
      guide_attrs = guide_attrs |> Map.merge(%{body: body})
      {:ok, guide_n} = CMS.create_article(community, :guide, guide_attrs, user)

      Hooks.Cite.handle(guide)
      Hooks.Cite.handle(guide_n)

      {:ok, guide2} = ORM.find(Guide, guide2.id)
      {:ok, guide3} = ORM.find(Guide, guide3.id)
      {:ok, guide4} = ORM.find(Guide, guide4.id)
      {:ok, guide5} = ORM.find(Guide, guide5.id)

      assert guide2.meta.citing_count == 1
      assert guide3.meta.citing_count == 2
      assert guide4.meta.citing_count == 1
      assert guide5.meta.citing_count == 1
    end

    test "cited guide itself should not work", ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/guide/#{guide.id} />))
      {:ok, guide} = CMS.update_article(guide, %{body: body})

      Hooks.Cite.handle(guide)

      {:ok, guide} = ORM.find(Guide, guide.id)
      assert guide.meta.citing_count == 0
    end

    test "cited comment itself should not work", ~m(user guide)a do
      {:ok, cited_comment} = CMS.create_comment(:guide, guide.id, mock_rich_text("hello"), user)

      {:ok, comment} =
        CMS.update_comment(
          cited_comment,
          mock_comment(
            ~s(the <a href=#{@site_host}/guide/#{guide.id}?comment_id=#{cited_comment.id} />)
          )
        )

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite guide's comment in guide", ~m(community user guide guide2 guide_attrs)a do
      {:ok, comment} = CMS.create_comment(:guide, guide.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/guide/#{guide2.id}?comment_id=#{comment.id} />)
        )

      guide_attrs = guide_attrs |> Map.merge(%{body: body})

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      Hooks.Cite.handle(guide)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: comment.id})

      # 被 guide 以 comment link 的方式引用了
      assert cited_content.guide_id == guide.id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user guide)a do
      {:ok, cited_comment} = CMS.create_comment(:guide, guide.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/guide/#{guide.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:guide, guide.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: cited_comment.id})
      assert comment.id == cited_content.comment_id
      assert cited_comment.id == cited_content.cited_by_id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cited guide inside a comment", ~m(user guide guide2 guide3 guide4 guide5)a do
      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/guide/#{guide2.id} /> and <a href=#{@site_host}/guide/#{
            guide2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/guide/#{guide3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/guide/#{guide2.id} class=#{guide2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/guide/#{guide4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/guide/#{
            guide5.id
          }> again</a>)
        )

      {:ok, comment} = CMS.create_comment(:guide, guide.id, comment_body, user)
      Hooks.Cite.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/guide/#{guide3.id} />))
      {:ok, comment} = CMS.create_comment(:guide, guide.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, guide2} = ORM.find(Guide, guide2.id)
      {:ok, guide3} = ORM.find(Guide, guide3.id)
      {:ok, guide4} = ORM.find(Guide, guide4.id)
      {:ok, guide5} = ORM.find(Guide, guide5.id)

      assert guide2.meta.citing_count == 1
      assert guide3.meta.citing_count == 2
      assert guide4.meta.citing_count == 1
      assert guide5.meta.citing_count == 1
    end
  end

  describe "[cite pagi]" do
    test "can get paged cited articles.", ~m(user community guide2 guide_attrs)a do
      {:ok, comment} =
        CMS.create_comment(
          :guide,
          guide2.id,
          mock_comment(~s(the <a href=#{@site_host}/guide/#{guide2.id} />)),
          user
        )

      Process.sleep(1000)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/guide/#{guide2.id} />),
          ~s(the <a href=#{@site_host}/guide/#{guide2.id} />)
        )

      guide_attrs = guide_attrs |> Map.merge(%{body: body})
      {:ok, guide_x} = CMS.create_article(community, :guide, guide_attrs, user)

      Process.sleep(1000)
      body = mock_rich_text(~s(the <a href=#{@site_host}/guide/#{guide2.id} />))
      guide_attrs = guide_attrs |> Map.merge(%{body: body})
      {:ok, guide_y} = CMS.create_article(community, :guide, guide_attrs, user)

      Hooks.Cite.handle(guide_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(guide_y)

      {:ok, result} = CMS.paged_citing_contents("GUIDE", guide2.id, %{page: 1, size: 10})

      entries = result.entries

      result_comment = entries |> List.first()
      result_guide_x = entries |> Enum.at(1)
      result_guide_y = entries |> List.last()

      article_map_keys = [:block_linker, :id, :inserted_at, :thread, :title, :user]

      assert result_comment.comment_id == comment.id
      assert result_comment.id == guide2.id
      assert result_comment.title == guide2.title

      assert result_guide_x.id == guide_x.id
      assert result_guide_x.block_linker |> length == 2
      assert result_guide_x |> Map.keys() == article_map_keys

      assert result_guide_y.id == guide_y.id
      assert result_guide_y.block_linker |> length == 1
      assert result_guide_y |> Map.keys() == article_map_keys

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 3
    end
  end
end
