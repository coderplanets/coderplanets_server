defmodule GroupherServer.Test.Articles.Radar do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  alias GroupherServer.{CMS, Repo}
  alias Helper.Converter.{EditorToHTML, HtmlSanitizer}

  alias EditorToHTML.{Class, Validator}
  alias CMS.Model.{Author, Radar, Community, ArticleDocument, RadarDocument}
  alias Helper.ORM

  @root_class Class.article()
  @last_year Timex.shift(Timex.beginning_of_year(Timex.now()), days: -3, seconds: -1)
  @article_digest_length get_config(:article, :digest_length)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    radar_attrs = mock_attrs(:radar, %{community_id: community.id})

    {:ok, ~m(user user2 community radar_attrs)a}
  end

  describe "[cms radars curd]" do
    test "can create radar with valid attrs", ~m(user community radar_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      radar = Repo.preload(radar, :document)

      body_map = Jason.decode!(radar.document.body)

      assert radar.meta.thread == "RADAR"

      assert radar.title == radar_attrs.title
      assert body_map |> Validator.is_valid()

      assert radar.document.body_html
             |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))

      assert radar.document.body_html |> String.contains?(~s(<p id="block-))

      paragraph_text = body_map["blocks"] |> List.first() |> get_in(["data", "text"])

      assert radar.digest ==
               paragraph_text
               |> HtmlSanitizer.strip_all_tags()
               |> String.slice(0, @article_digest_length)
    end

    test "created radar should have a acitve_at field, same with inserted_at",
         ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      assert radar.active_at == radar.inserted_at
    end

    test "read radar should update views and meta viewed_user_list",
         ~m(radar_attrs community user user2)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _} = CMS.read_article(:radar, radar.id, user)
      {:ok, _created} = ORM.find(Radar, radar.id)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:radar, radar.id, user)
      {:ok, created} = ORM.find(Radar, radar.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:radar, radar.id, user2)
      {:ok, created} = ORM.find(Radar, radar.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    test "read radar should contains viewer_has_xxx state",
         ~m(radar_attrs community user user2)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, radar} = CMS.read_article(:radar, radar.id, user)

      assert not radar.viewer_has_collected
      assert not radar.viewer_has_upvoted
      assert not radar.viewer_has_reported

      {:ok, radar} = CMS.read_article(:radar, radar.id)

      assert not radar.viewer_has_collected
      assert not radar.viewer_has_upvoted
      assert not radar.viewer_has_reported

      {:ok, radar} = CMS.read_article(:radar, radar.id, user2)

      assert not radar.viewer_has_collected
      assert not radar.viewer_has_upvoted
      assert not radar.viewer_has_reported

      {:ok, _} = CMS.upvote_article(:radar, radar.id, user)
      {:ok, _} = CMS.collect_article(:radar, radar.id, user)
      {:ok, _} = CMS.report_article(:radar, radar.id, "reason", "attr_info", user)

      {:ok, radar} = CMS.read_article(:radar, radar.id, user)

      assert radar.viewer_has_collected
      assert radar.viewer_has_upvoted
      assert radar.viewer_has_reported
    end

    test "create radar with an exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:radar, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :radar, invalid_attrs, user)
    end
  end

  describe "[cms radar sink/undo_sink]" do
    test "if a radar is too old, read radar should update can_undo_sink flag",
         ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      assert radar.meta.can_undo_sink

      {:ok, radar_last_year} = db_insert(:radar, %{title: "last year", inserted_at: @last_year})
      {:ok, radar_last_year} = CMS.read_article(:radar, radar_last_year.id)
      assert not radar_last_year.meta.can_undo_sink

      {:ok, radar_last_year} = CMS.read_article(:radar, radar_last_year.id, user)
      assert not radar_last_year.meta.can_undo_sink
    end

    test "can sink a radar", ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      assert not radar.meta.is_sinked

      {:ok, radar} = CMS.sink_article(:radar, radar.id)
      assert radar.meta.is_sinked
      assert radar.active_at == radar.inserted_at
    end

    test "can undo sink radar", ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, radar} = CMS.sink_article(:radar, radar.id)
      assert radar.meta.is_sinked
      assert radar.meta.last_active_at == radar.active_at

      {:ok, radar} = CMS.undo_sink_article(:radar, radar.id)
      assert not radar.meta.is_sinked
      assert radar.active_at == radar.meta.last_active_at
    end

    test "can not undo sink to old radar", ~m()a do
      {:ok, radar_last_year} = db_insert(:radar, %{title: "last year", inserted_at: @last_year})

      {:error, reason} = CMS.undo_sink_article(:radar, radar_last_year.id)
      is_error?(reason, :undo_sink_old_article)
    end
  end

  describe "[cms radar document]" do
    test "will create related document after create", ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, radar} = CMS.read_article(:radar, radar.id)
      assert not is_nil(radar.document.body_html)
      {:ok, radar} = CMS.read_article(:radar, radar.id, user)
      assert not is_nil(radar.document.body_html)

      {:ok, article_doc} = ORM.find_by(ArticleDocument, %{article_id: radar.id, thread: "RADAR"})
      {:ok, radar_doc} = ORM.find_by(RadarDocument, %{radar_id: radar.id})

      assert radar.document.body == radar_doc.body
      assert article_doc.body == radar_doc.body
    end

    test "delete radar should also delete related document", ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _article_doc} = ORM.find_by(ArticleDocument, %{article_id: radar.id, thread: "RADAR"})
      {:ok, _radar_doc} = ORM.find_by(RadarDocument, %{radar_id: radar.id})

      {:ok, _} = CMS.delete_article(radar)

      {:error, _} = ORM.find(Radar, radar.id)
      {:error, _} = ORM.find_by(ArticleDocument, %{article_id: radar.id, thread: "RADAR"})
      {:error, _} = ORM.find_by(RadarDocument, %{radar_id: radar.id})
    end

    test "update radar should also update related document", ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      body = mock_rich_text(~s(new content))
      {:ok, radar} = CMS.update_article(radar, %{body: body})

      {:ok, article_doc} = ORM.find_by(ArticleDocument, %{article_id: radar.id, thread: "RADAR"})
      {:ok, radar_doc} = ORM.find_by(RadarDocument, %{radar_id: radar.id})

      assert String.contains?(radar_doc.body, "new content")
      assert String.contains?(article_doc.body, "new content")
    end
  end
end
