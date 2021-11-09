defmodule GroupherServer.Test.Articles.Works do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  alias GroupherServer.{CMS, Repo}
  alias Helper.Converter.{EditorToHTML, HtmlSanitizer}

  alias EditorToHTML.{Class, Validator}
  alias CMS.Model.{Author, Works, Community, ArticleDocument, WorksDocument}
  alias Helper.ORM

  @root_class Class.article()
  @last_year Timex.shift(Timex.beginning_of_year(Timex.now()), days: -3, seconds: -1)
  @article_digest_length get_config(:article, :digest_length)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community, %{raw: "home"})

    works_attrs = mock_attrs(:works, %{community_id: community.id})

    {:ok, ~m(user user2 community works_attrs)a}
  end

  describe "[cms real works curd]" do
    test "create works with full attrs", ~m(user works_attrs)a do
      social_info = [
        %{platform: "github", link: "https://github.com/xxx"},
        %{platform: "twitter", link: "https://twitter.com/xxx"}
      ]

      app_store = [
        %{platform: "apple", link: "https://apple.com/xxx"},
        %{platform: "google", link: "https://google.com/xxx"},
        %{platform: "others", link: "https://others.com/xxx"}
      ]

      attrs =
        works_attrs
        |> Map.merge(%{
          title: "title",
          desc: "cool works",
          profit_mode: "FREE",
          working_mode: "FULLTIME",
          techstacks: ["elixir", "React"],
          cities: ["chengdu", "xiamen"],
          teammates: [user.login],
          social_info: social_info,
          app_store: app_store
        })

      {:ok, works} = CMS.create_works(attrs, user)

      assert works.title == "title"
      assert works.desc == "cool works"
      assert works.profit_mode == "FREE"
      assert works.working_mode == "FULLTIME"

      assert works.teammates |> List.first() |> Map.get(:login) === user.login

      assert not is_nil(works.social_info)
      assert not is_nil(works.app_store)
      assert not is_nil(works.cities)
    end

    test "create works with minimal attrs", ~m(user works_attrs)a do
      attrs =
        works_attrs
        |> Map.merge(%{
          profit_mode: "love",
          working_mode: "fulltime"
        })

      {:ok, works} = CMS.create_works(attrs, user)

      # IO.inspect(works, label: "the attrs")
      assert works.profit_mode == "love"
      assert works.working_mode == "fulltime"
    end

    test "create works with exsit communit should have same attrs", ~m(user works_attrs)a do
      {:ok, _community} = db_insert(:community, %{title: "Elixir", raw: "elixir"})

      attrs =
        works_attrs
        |> Map.merge(%{
          techstacks: ["elixir", "React"]
        })

      {:ok, works} = CMS.create_works(attrs, user)

      techstack = works.techstacks |> List.first()

      assert techstack.title == "Elixir"
      assert techstack.raw == "elixir"
    end

    test "update works with full attrs", ~m(user user2 works_attrs)a do
      works_attrs = works_attrs |> Map.merge(%{teammates: [user.login]})
      {:ok, works} = CMS.create_works(works_attrs, user)
      assert works.teammates |> length == 1

      social_info = [
        %{platform: "github", link: "https://github.com/xxx"},
        %{platform: "twitter", link: "https://twitter.com/xxx"}
      ]

      app_store = [
        %{platform: "apple", link: "https://apple.com/xxx"},
        %{platform: "google", link: "https://google.com/xxx"},
        %{platform: "others", link: "https://others.com/xxx"}
      ]

      teammates = [user.login, user2.login]

      {:ok, works} =
        CMS.update_works(works, %{
          social_info: social_info,
          app_store: app_store,
          teammates: teammates
        })

      assert works.teammates |> length == 2

      assert not is_nil(works.social_info)
      assert not is_nil(works.app_store)
    end
  end

  describe "[cms works curd]" do
    test "can create works with valid attrs", ~m(user community works_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      works = Repo.preload(works, :document)

      body_map = Jason.decode!(works.document.body)

      assert works.meta.thread == "WORKS"

      assert works.title == works_attrs.title
      assert body_map |> Validator.is_valid()

      assert works.document.body_html
             |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))

      assert works.document.body_html |> String.contains?(~s(<p id="block-))

      paragraph_text = body_map["blocks"] |> List.first() |> get_in(["data", "text"])

      assert works.digest ==
               paragraph_text
               |> HtmlSanitizer.strip_all_tags()
               |> String.slice(0, @article_digest_length)
    end

    test "created works should have a acitve_at field, same with inserted_at",
         ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      assert works.active_at == works.inserted_at
    end

    test "read works should update views and meta viewed_user_list",
         ~m(works_attrs community user user2)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _} = CMS.read_article(:works, works.id, user)
      {:ok, _created} = ORM.find(Works, works.id)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:works, works.id, user)
      {:ok, created} = ORM.find(Works, works.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:works, works.id, user2)
      {:ok, created} = ORM.find(Works, works.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    test "read works should contains viewer_has_xxx state",
         ~m(works_attrs community user user2)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, works} = CMS.read_article(:works, works.id, user)

      assert not works.viewer_has_collected
      assert not works.viewer_has_upvoted
      assert not works.viewer_has_reported

      {:ok, works} = CMS.read_article(:works, works.id)

      assert not works.viewer_has_collected
      assert not works.viewer_has_upvoted
      assert not works.viewer_has_reported

      {:ok, works} = CMS.read_article(:works, works.id, user2)

      assert not works.viewer_has_collected
      assert not works.viewer_has_upvoted
      assert not works.viewer_has_reported

      {:ok, _} = CMS.upvote_article(:works, works.id, user)
      {:ok, _} = CMS.collect_article(:works, works.id, user)
      {:ok, _} = CMS.report_article(:works, works.id, "reason", "attr_info", user)

      {:ok, works} = CMS.read_article(:works, works.id, user)

      assert works.viewer_has_collected
      assert works.viewer_has_upvoted
      assert works.viewer_has_reported
    end

    test "create works with an exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:works, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :works, invalid_attrs, user)
    end
  end

  describe "[cms works sink/undo_sink]" do
    test "if a works is too old, read works should update can_undo_sink flag",
         ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      assert works.meta.can_undo_sink

      {:ok, works_last_year} = db_insert(:works, %{title: "last year", inserted_at: @last_year})
      {:ok, works_last_year} = CMS.read_article(:works, works_last_year.id)
      assert not works_last_year.meta.can_undo_sink

      {:ok, works_last_year} = CMS.read_article(:works, works_last_year.id, user)
      assert not works_last_year.meta.can_undo_sink
    end

    test "can sink a works", ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      assert not works.meta.is_sinked

      {:ok, works} = CMS.sink_article(:works, works.id)
      assert works.meta.is_sinked
      assert works.active_at == works.inserted_at
    end

    test "can undo sink works", ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, works} = CMS.sink_article(:works, works.id)
      assert works.meta.is_sinked
      assert works.meta.last_active_at == works.active_at

      {:ok, works} = CMS.undo_sink_article(:works, works.id)
      assert not works.meta.is_sinked
      assert works.active_at == works.meta.last_active_at
    end

    test "can not undo sink to old works", ~m()a do
      {:ok, works_last_year} = db_insert(:works, %{title: "last year", inserted_at: @last_year})

      {:error, reason} = CMS.undo_sink_article(:works, works_last_year.id)
      is_error?(reason, :undo_sink_old_article)
    end
  end

  describe "[cms works document]" do
    test "will create related document after create", ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, works} = CMS.read_article(:works, works.id)
      assert not is_nil(works.document.body_html)
      {:ok, works} = CMS.read_article(:works, works.id, user)
      assert not is_nil(works.document.body_html)

      {:ok, article_doc} = ORM.find_by(ArticleDocument, %{article_id: works.id, thread: "WORKS"})
      {:ok, works_doc} = ORM.find_by(WorksDocument, %{works_id: works.id})

      assert works.document.body == works_doc.body
      assert article_doc.body == works_doc.body
    end

    test "delete works should also delete related document", ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _article_doc} = ORM.find_by(ArticleDocument, %{article_id: works.id, thread: "WORKS"})
      {:ok, _works_doc} = ORM.find_by(WorksDocument, %{works_id: works.id})

      {:ok, _} = CMS.delete_article(works)

      {:error, _} = ORM.find(Works, works.id)
      {:error, _} = ORM.find_by(ArticleDocument, %{article_id: works.id, thread: "WORKS"})
      {:error, _} = ORM.find_by(WorksDocument, %{works_id: works.id})
    end

    test "update works should also update related document", ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      body = mock_rich_text(~s(new content))
      {:ok, works} = CMS.update_article(works, %{body: body})

      {:ok, article_doc} = ORM.find_by(ArticleDocument, %{article_id: works.id, thread: "WORKS"})
      {:ok, works_doc} = ORM.find_by(WorksDocument, %{works_id: works.id})

      assert String.contains?(works_doc.body, "new content")
      assert String.contains?(article_doc.body, "new content")
    end
  end
end
