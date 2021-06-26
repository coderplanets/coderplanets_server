defmodule GroupherServer.Test.CMS.Artilces.GuidePin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)

    {:ok, ~m(user community guide)a}
  end

  describe "[cms guide pin]" do
    test "can pin a guide", ~m(community guide)a do
      {:ok, _} = CMS.pin_article(:guide, guide.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{guide_id: guide.id})

      assert pind_article.guide_id == guide.id
    end

    test "one community & thread can only pin certern count of guide", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)
        {:ok, _} = CMS.pin_article(:guide, new_guide.id, community.id)
        acc
      end)

      {:ok, new_guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)
      {:error, reason} = CMS.pin_article(:guide, new_guide.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit guide", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:guide, 8848, community.id)
    end

    test "can undo pin to a guide", ~m(community guide)a do
      {:ok, _} = CMS.pin_article(:guide, guide.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:guide, guide.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{guide_id: guide.id})
    end
  end
end
