defmodule GroupherServer.Test.CMS.Hooks.CiteMeetup do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Meetup, Comment, CitedArtiment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, meetup} = db_insert(:meetup)
    {:ok, meetup2} = db_insert(:meetup)
    {:ok, meetup3} = db_insert(:meetup)
    {:ok, meetup4} = db_insert(:meetup)
    {:ok, meetup5} = db_insert(:meetup)

    {:ok, community} = db_insert(:community)

    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})

    {:ok, ~m(user user2 community meetup meetup2 meetup3 meetup4 meetup5 meetup_attrs)a}
  end

  describe "[cite basic]" do
    test "cited multi meetup should work",
         ~m(user community meetup2 meetup3 meetup4 meetup5 meetup_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/meetup/#{meetup2.id} /> and <a href=#{@site_host}/meetup/#{
            meetup2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/meetup/#{meetup3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/meetup/#{meetup2.id} class=#{meetup2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/meetup/#{meetup4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/meetup/#{
            meetup5.id
          }> again</a>)
        )

      meetup_attrs = meetup_attrs |> Map.merge(%{body: body})
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/meetup/#{meetup3.id} />))
      meetup_attrs = meetup_attrs |> Map.merge(%{body: body})
      {:ok, meetup_n} = CMS.create_article(community, :meetup, meetup_attrs, user)

      Hooks.Cite.handle(meetup)
      Hooks.Cite.handle(meetup_n)

      {:ok, meetup2} = ORM.find(Meetup, meetup2.id)
      {:ok, meetup3} = ORM.find(Meetup, meetup3.id)
      {:ok, meetup4} = ORM.find(Meetup, meetup4.id)
      {:ok, meetup5} = ORM.find(Meetup, meetup5.id)

      assert meetup2.meta.citing_count == 1
      assert meetup3.meta.citing_count == 2
      assert meetup4.meta.citing_count == 1
      assert meetup5.meta.citing_count == 1
    end

    test "cited meetup itself should not work", ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/meetup/#{meetup.id} />))
      {:ok, meetup} = CMS.update_article(meetup, %{body: body})

      Hooks.Cite.handle(meetup)

      {:ok, meetup} = ORM.find(Meetup, meetup.id)
      assert meetup.meta.citing_count == 0
    end

    test "cited comment itself should not work", ~m(user meetup)a do
      {:ok, cited_comment} = CMS.create_comment(:meetup, meetup.id, mock_rich_text("hello"), user)

      {:ok, comment} =
        CMS.update_comment(
          cited_comment,
          mock_comment(
            ~s(the <a href=#{@site_host}/meetup/#{meetup.id}?comment_id=#{cited_comment.id} />)
          )
        )

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite meetup's comment in meetup", ~m(community user meetup meetup2 meetup_attrs)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/meetup/#{meetup2.id}?comment_id=#{comment.id} />)
        )

      meetup_attrs = meetup_attrs |> Map.merge(%{body: body})

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      Hooks.Cite.handle(meetup)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: comment.id})

      # 被 meetup 以 comment link 的方式引用了
      assert cited_content.meetup_id == meetup.id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user meetup)a do
      {:ok, cited_comment} = CMS.create_comment(:meetup, meetup.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/meetup/#{meetup.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: cited_comment.id})
      assert comment.id == cited_content.comment_id
      assert cited_comment.id == cited_content.cited_by_id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cited meetup inside a comment", ~m(user meetup meetup2 meetup3 meetup4 meetup5)a do
      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/meetup/#{meetup2.id} /> and <a href=#{@site_host}/meetup/#{
            meetup2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/meetup/#{meetup3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/meetup/#{meetup2.id} class=#{meetup2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/meetup/#{meetup4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/meetup/#{
            meetup5.id
          }> again</a>)
        )

      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, comment_body, user)
      Hooks.Cite.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/meetup/#{meetup3.id} />))
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, meetup2} = ORM.find(Meetup, meetup2.id)
      {:ok, meetup3} = ORM.find(Meetup, meetup3.id)
      {:ok, meetup4} = ORM.find(Meetup, meetup4.id)
      {:ok, meetup5} = ORM.find(Meetup, meetup5.id)

      assert meetup2.meta.citing_count == 1
      assert meetup3.meta.citing_count == 2
      assert meetup4.meta.citing_count == 1
      assert meetup5.meta.citing_count == 1
    end
  end

  describe "[cite pagi]" do
    test "can get paged cited articles.", ~m(user community meetup2 meetup_attrs)a do
      {:ok, comment} =
        CMS.create_comment(
          :meetup,
          meetup2.id,
          mock_comment(~s(the <a href=#{@site_host}/meetup/#{meetup2.id} />)),
          user
        )

      Process.sleep(1000)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/meetup/#{meetup2.id} />),
          ~s(the <a href=#{@site_host}/meetup/#{meetup2.id} />)
        )

      meetup_attrs = meetup_attrs |> Map.merge(%{body: body})
      {:ok, meetup_x} = CMS.create_article(community, :meetup, meetup_attrs, user)

      Process.sleep(1000)
      body = mock_rich_text(~s(the <a href=#{@site_host}/meetup/#{meetup2.id} />))
      meetup_attrs = meetup_attrs |> Map.merge(%{body: body})
      {:ok, meetup_y} = CMS.create_article(community, :meetup, meetup_attrs, user)

      Hooks.Cite.handle(meetup_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(meetup_y)

      {:ok, result} = CMS.paged_citing_contents("MEETUP", meetup2.id, %{page: 1, size: 10})

      entries = result.entries

      result_comment = entries |> List.first()
      result_meetup_x = entries |> Enum.at(1)
      result_meetup_y = entries |> List.last()

      article_map_keys = [:block_linker, :id, :inserted_at, :thread, :title, :user]

      assert result_comment.comment_id == comment.id
      assert result_comment.id == meetup2.id
      assert result_comment.title == meetup2.title

      assert result_meetup_x.id == meetup_x.id
      assert result_meetup_x.block_linker |> length == 2
      assert result_meetup_x |> Map.keys() == article_map_keys

      assert result_meetup_y.id == meetup_y.id
      assert result_meetup_y.block_linker |> length == 1
      assert result_meetup_y |> Map.keys() == article_map_keys

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 3
    end
  end
end
