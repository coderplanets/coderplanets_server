defmodule GroupherServer.Test.CMS.Hooks.CiteRadar do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Radar, Comment, CitedArtiment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, radar} = db_insert(:radar)
    {:ok, radar2} = db_insert(:radar)
    {:ok, radar3} = db_insert(:radar)
    {:ok, radar4} = db_insert(:radar)
    {:ok, radar5} = db_insert(:radar)

    {:ok, community} = db_insert(:community)

    radar_attrs = mock_attrs(:radar, %{community_id: community.id})

    {:ok, ~m(user user2 community radar radar2 radar3 radar4 radar5 radar_attrs)a}
  end

  describe "[cite basic]" do
    test "cited multi radar should work",
         ~m(user community radar2 radar3 radar4 radar5 radar_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/radar/#{radar2.id} /> and <a href=#{@site_host}/radar/#{
            radar2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/radar/#{radar3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/radar/#{radar2.id} class=#{radar2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/radar/#{radar4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/radar/#{
            radar5.id
          }> again</a>)
        )

      radar_attrs = radar_attrs |> Map.merge(%{body: body})
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/radar/#{radar3.id} />))
      radar_attrs = radar_attrs |> Map.merge(%{body: body})
      {:ok, radar_n} = CMS.create_article(community, :radar, radar_attrs, user)

      Hooks.Cite.handle(radar)
      Hooks.Cite.handle(radar_n)

      {:ok, radar2} = ORM.find(Radar, radar2.id)
      {:ok, radar3} = ORM.find(Radar, radar3.id)
      {:ok, radar4} = ORM.find(Radar, radar4.id)
      {:ok, radar5} = ORM.find(Radar, radar5.id)

      assert radar2.meta.citing_count == 1
      assert radar3.meta.citing_count == 2
      assert radar4.meta.citing_count == 1
      assert radar5.meta.citing_count == 1
    end

    test "cited radar itself should not work", ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/radar/#{radar.id} />))
      {:ok, radar} = CMS.update_article(radar, %{body: body})

      Hooks.Cite.handle(radar)

      {:ok, radar} = ORM.find(Radar, radar.id)
      assert radar.meta.citing_count == 0
    end

    test "cited comment itself should not work", ~m(user radar)a do
      {:ok, cited_comment} = CMS.create_comment(:radar, radar.id, mock_rich_text("hello"), user)

      {:ok, comment} =
        CMS.update_comment(
          cited_comment,
          mock_comment(
            ~s(the <a href=#{@site_host}/radar/#{radar.id}?comment_id=#{cited_comment.id} />)
          )
        )

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite radar's comment in radar", ~m(community user radar radar2 radar_attrs)a do
      {:ok, comment} = CMS.create_comment(:radar, radar.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/radar/#{radar2.id}?comment_id=#{comment.id} />)
        )

      radar_attrs = radar_attrs |> Map.merge(%{body: body})

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      Hooks.Cite.handle(radar)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: comment.id})

      # 被 radar 以 comment link 的方式引用了
      assert cited_content.radar_id == radar.id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user radar)a do
      {:ok, cited_comment} = CMS.create_comment(:radar, radar.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/radar/#{radar.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:radar, radar.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: cited_comment.id})
      assert comment.id == cited_content.comment_id
      assert cited_comment.id == cited_content.cited_by_id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cited radar inside a comment", ~m(user radar radar2 radar3 radar4 radar5)a do
      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/radar/#{radar2.id} /> and <a href=#{@site_host}/radar/#{
            radar2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/radar/#{radar3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/radar/#{radar2.id} class=#{radar2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/radar/#{radar4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/radar/#{
            radar5.id
          }> again</a>)
        )

      {:ok, comment} = CMS.create_comment(:radar, radar.id, comment_body, user)
      Hooks.Cite.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/radar/#{radar3.id} />))
      {:ok, comment} = CMS.create_comment(:radar, radar.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, radar2} = ORM.find(Radar, radar2.id)
      {:ok, radar3} = ORM.find(Radar, radar3.id)
      {:ok, radar4} = ORM.find(Radar, radar4.id)
      {:ok, radar5} = ORM.find(Radar, radar5.id)

      assert radar2.meta.citing_count == 1
      assert radar3.meta.citing_count == 2
      assert radar4.meta.citing_count == 1
      assert radar5.meta.citing_count == 1
    end
  end

  describe "[cite pagi]" do
    test "can get paged cited articles.", ~m(user community radar2 radar_attrs)a do
      {:ok, comment} =
        CMS.create_comment(
          :radar,
          radar2.id,
          mock_comment(~s(the <a href=#{@site_host}/radar/#{radar2.id} />)),
          user
        )

      Process.sleep(1000)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/radar/#{radar2.id} />),
          ~s(the <a href=#{@site_host}/radar/#{radar2.id} />)
        )

      radar_attrs = radar_attrs |> Map.merge(%{body: body})
      {:ok, radar_x} = CMS.create_article(community, :radar, radar_attrs, user)

      Process.sleep(1000)
      body = mock_rich_text(~s(the <a href=#{@site_host}/radar/#{radar2.id} />))
      radar_attrs = radar_attrs |> Map.merge(%{body: body})
      {:ok, radar_y} = CMS.create_article(community, :radar, radar_attrs, user)

      Hooks.Cite.handle(radar_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(radar_y)

      {:ok, result} = CMS.paged_citing_contents("RADAR", radar2.id, %{page: 1, size: 10})

      entries = result.entries

      result_comment = entries |> List.first()
      result_radar_x = entries |> Enum.at(1)
      result_radar_y = entries |> List.last()

      article_map_keys = [:block_linker, :id, :inserted_at, :thread, :title, :user]

      assert result_comment.comment_id == comment.id
      assert result_comment.id == radar2.id
      assert result_comment.title == radar2.title

      assert result_radar_x.id == radar_x.id
      assert result_radar_x.block_linker |> length == 2
      assert result_radar_x |> Map.keys() == article_map_keys

      assert result_radar_y.id == radar_y.id
      assert result_radar_y.block_linker |> length == 1
      assert result_radar_y |> Map.keys() == article_map_keys

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 3
    end
  end
end
