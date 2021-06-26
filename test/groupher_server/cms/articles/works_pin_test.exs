defmodule GroupherServer.Test.CMS.Artilces.WorksPin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, works} = CMS.create_article(community, :works, mock_attrs(:works), user)

    {:ok, ~m(user community works)a}
  end

  describe "[cms works pin]" do
    test "can pin a works", ~m(community works)a do
      {:ok, _} = CMS.pin_article(:works, works.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{works_id: works.id})

      assert pind_article.works_id == works.id
    end

    test "one community & thread can only pin certern count of works", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_works} = CMS.create_article(community, :works, mock_attrs(:works), user)
        {:ok, _} = CMS.pin_article(:works, new_works.id, community.id)
        acc
      end)

      {:ok, new_works} = CMS.create_article(community, :works, mock_attrs(:works), user)
      {:error, reason} = CMS.pin_article(:works, new_works.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit works", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:works, 8848, community.id)
    end

    test "can undo pin to a works", ~m(community works)a do
      {:ok, _} = CMS.pin_article(:works, works.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:works, works.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{works_id: works.id})
    end
  end
end
