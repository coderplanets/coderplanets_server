defmodule GroupherServer.Test.Articles.Meetup do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias Helper.Converter.{EditorToHTML, HtmlSanitizer}

  alias EditorToHTML.{Class, Validator}
  alias CMS.Model.{Author, Meetup, Community, ArticleDocument, MeetupDocument}
  alias Helper.ORM

  @root_class Class.article()
  @last_year Timex.shift(Timex.beginning_of_year(Timex.now()), days: -3, seconds: -1)
  @article_digest_length get_config(:article, :digest_length)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})

    {:ok, ~m(user user2 community meetup_attrs)a}
  end

  describe "[cms meetups curd]" do
    test "can create meetup with valid attrs", ~m(user community meetup_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      meetup = Repo.preload(meetup, :document)

      body_map = Jason.decode!(meetup.document.body)

      assert meetup.meta.thread == "MEETUP"

      assert meetup.title == meetup_attrs.title
      assert body_map |> Validator.is_valid()

      assert meetup.document.body_html
             |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))

      assert meetup.document.body_html |> String.contains?(~s(<p id="block-))

      paragraph_text = body_map["blocks"] |> List.first() |> get_in(["data", "text"])
      assert meetup.digest == paragraph_text |> HtmlSanitizer.strip_all_tags()

      assert meetup.digest ==
               paragraph_text
               |> HtmlSanitizer.strip_all_tags()
               |> String.slice(0, @article_digest_length)
    end

    test "created meetup should have a acitve_at field, same with inserted_at",
         ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      assert meetup.active_at == meetup.inserted_at
    end

    test "read meetup should update views and meta viewed_user_list",
         ~m(meetup_attrs community user user2)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.read_article(:meetup, meetup.id, user)
      {:ok, _created} = ORM.find(Meetup, meetup.id)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:meetup, meetup.id, user)
      {:ok, created} = ORM.find(Meetup, meetup.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:meetup, meetup.id, user2)
      {:ok, created} = ORM.find(Meetup, meetup.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    test "read meetup should contains viewer_has_xxx state",
         ~m(meetup_attrs community user user2)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, meetup} = CMS.read_article(:meetup, meetup.id, user)

      assert not meetup.viewer_has_collected
      assert not meetup.viewer_has_upvoted
      assert not meetup.viewer_has_reported

      {:ok, meetup} = CMS.read_article(:meetup, meetup.id)

      assert not meetup.viewer_has_collected
      assert not meetup.viewer_has_upvoted
      assert not meetup.viewer_has_reported

      {:ok, meetup} = CMS.read_article(:meetup, meetup.id, user2)

      assert not meetup.viewer_has_collected
      assert not meetup.viewer_has_upvoted
      assert not meetup.viewer_has_reported

      {:ok, _} = CMS.upvote_article(:meetup, meetup.id, user)
      {:ok, _} = CMS.collect_article(:meetup, meetup.id, user)
      {:ok, _} = CMS.report_article(:meetup, meetup.id, "reason", "attr_info", user)

      {:ok, meetup} = CMS.read_article(:meetup, meetup.id, user)

      assert meetup.viewer_has_collected
      assert meetup.viewer_has_upvoted
      assert meetup.viewer_has_reported
    end

    test "create meetup with an exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:meetup, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :meetup, invalid_attrs, user)
    end
  end

  describe "[cms meetup sink/undo_sink]" do
    test "if a meetup is too old, read meetup should update can_undo_sink flag",
         ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      assert meetup.meta.can_undo_sink

      {:ok, meetup_last_year} = db_insert(:meetup, %{title: "last year", inserted_at: @last_year})
      {:ok, meetup_last_year} = CMS.read_article(:meetup, meetup_last_year.id)
      assert not meetup_last_year.meta.can_undo_sink

      {:ok, meetup_last_year} = CMS.read_article(:meetup, meetup_last_year.id, user)
      assert not meetup_last_year.meta.can_undo_sink
    end

    test "can sink a meetup", ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      assert not meetup.meta.is_sinked

      {:ok, meetup} = CMS.sink_article(:meetup, meetup.id)
      assert meetup.meta.is_sinked
      assert meetup.active_at == meetup.inserted_at
    end

    test "can undo sink meetup", ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, meetup} = CMS.sink_article(:meetup, meetup.id)
      assert meetup.meta.is_sinked
      assert meetup.meta.last_active_at == meetup.active_at

      {:ok, meetup} = CMS.undo_sink_article(:meetup, meetup.id)
      assert not meetup.meta.is_sinked
      assert meetup.active_at == meetup.meta.last_active_at
    end

    test "can not undo sink to old meetup", ~m()a do
      {:ok, meetup_last_year} = db_insert(:meetup, %{title: "last year", inserted_at: @last_year})

      {:error, reason} = CMS.undo_sink_article(:meetup, meetup_last_year.id)
      is_error?(reason, :undo_sink_old_article)
    end
  end

  describe "[cms meetup document]" do
    test "will create related document after create", ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, meetup} = CMS.read_article(:meetup, meetup.id)
      assert not is_nil(meetup.document.body_html)
      {:ok, meetup} = CMS.read_article(:meetup, meetup.id, user)
      assert not is_nil(meetup.document.body_html)

      {:ok, article_doc} =
        ORM.find_by(ArticleDocument, %{article_id: meetup.id, thread: "MEETUP"})

      {:ok, meetup_doc} = ORM.find_by(MeetupDocument, %{meetup_id: meetup.id})

      assert meetup.document.body == meetup_doc.body
      assert article_doc.body == meetup_doc.body
    end

    test "delete meetup should also delete related document", ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      {:ok, _article_doc} =
        ORM.find_by(ArticleDocument, %{article_id: meetup.id, thread: "MEETUP"})

      {:ok, _meetup_doc} = ORM.find_by(MeetupDocument, %{meetup_id: meetup.id})

      {:ok, _} = CMS.delete_article(meetup)

      {:error, _} = ORM.find(Meetup, meetup.id)
      {:error, _} = ORM.find_by(ArticleDocument, %{article_id: meetup.id, thread: "MEETUP"})
      {:error, _} = ORM.find_by(MeetupDocument, %{meetup_id: meetup.id})
    end

    test "update meetup should also update related document", ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      body = mock_rich_text(~s(new content))
      {:ok, meetup} = CMS.update_article(meetup, %{body: body})

      {:ok, article_doc} =
        ORM.find_by(ArticleDocument, %{article_id: meetup.id, thread: "MEETUP"})

      {:ok, meetup_doc} = ORM.find_by(MeetupDocument, %{meetup_id: meetup.id})

      assert String.contains?(meetup_doc.body, "new content")
      assert String.contains?(article_doc.body, "new content")
    end
  end
end
