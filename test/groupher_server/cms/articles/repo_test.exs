defmodule GroupherServer.Test.Articles.Repo do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  @last_year Timex.shift(Timex.beginning_of_year(Timex.now()), days: -3, seconds: -1)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    # {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    repo_attrs = mock_attrs(:repo, %{community_id: community.id})

    {:ok, ~m(user user2 community repo_attrs)a}
  end

  describe "[cms repo curd]" do
    alias CMS.{Author, Community}

    test "can create repo with valid attrs", ~m(user community repo_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      assert repo.title == repo_attrs.title
      assert repo.contributors |> length !== 0
    end

    test "created repo should have a acitve_at field, same with inserted_at",
         ~m(user community repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      assert repo.active_at == repo.inserted_at
    end

    test "read repo should update views and meta viewed_user_list",
         ~m(repo_attrs community user user2)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _} = CMS.read_article(:repo, repo.id, user)
      {:ok, _created} = ORM.find(CMS.Repo, repo.id)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:repo, repo.id, user)
      {:ok, created} = ORM.find(CMS.Repo, repo.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:repo, repo.id, user2)
      {:ok, created} = ORM.find(CMS.Repo, repo.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    test "read repo should contains viewer_has_xxx state", ~m(repo_attrs community user user2)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, repo} = CMS.read_article(:repo, repo.id, user)

      assert not repo.viewer_has_collected
      assert not repo.viewer_has_upvoted
      assert not repo.viewer_has_reported

      {:ok, repo} = CMS.read_article(:repo, repo.id)

      assert not repo.viewer_has_collected
      assert not repo.viewer_has_upvoted
      assert not repo.viewer_has_reported

      {:ok, repo} = CMS.read_article(:repo, repo.id, user2)

      assert not repo.viewer_has_collected
      assert not repo.viewer_has_upvoted
      assert not repo.viewer_has_reported

      {:ok, _} = CMS.upvote_article(:repo, repo.id, user)
      {:ok, _} = CMS.collect_article(:repo, repo.id, user)
      {:ok, _} = CMS.report_article(:repo, repo.id, "reason", "attr_info", user)

      {:ok, repo} = CMS.read_article(:repo, repo.id, user)

      assert repo.viewer_has_collected
      assert repo.viewer_has_upvoted
      assert repo.viewer_has_reported
    end

    test "add user to cms authors, if the user is not exsit in cms authors",
         ~m(user community repo_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, _} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, author} = ORM.find_by(Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create repo with an exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:post, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :repo, invalid_attrs, user)
    end
  end

  describe "[cms repo sink/undo_sink]" do
    @tag :wip2
    test "if a repo is too old, read repo should update can_undo_sink flag",
         ~m(user community repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      assert repo.meta.can_undo_sink

      {:ok, repo_last_year} = db_insert(:repo, %{title: "last year", inserted_at: @last_year})
      {:ok, repo_last_year} = CMS.read_article(:repo, repo_last_year.id)
      assert not repo_last_year.meta.can_undo_sink

      {:ok, repo_last_year} = CMS.read_article(:repo, repo_last_year.id, user)
      assert not repo_last_year.meta.can_undo_sink
    end

    @tag :wip2
    test "can sink a repo", ~m(user community repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      assert not repo.meta.is_sinked

      {:ok, repo} = CMS.sink_article(:repo, repo.id)
      assert repo.meta.is_sinked
    end

    @tag :wip2
    test "can undo sink repo", ~m(user community repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, repo} = CMS.sink_article(:repo, repo.id)
      assert repo.meta.is_sinked

      {:ok, repo} = CMS.undo_sink_article(:repo, repo.id)
      assert not repo.meta.is_sinked
    end

    @tag :wip2
    test "can not undo sink to old repo", ~m()a do
      {:ok, repo_last_year} = db_insert(:repo, %{title: "last year", inserted_at: @last_year})

      {:error, reason} = CMS.undo_sink_article(:repo, repo_last_year.id)
      is_error?(reason, :undo_sink_old_article)
    end
  end
end
