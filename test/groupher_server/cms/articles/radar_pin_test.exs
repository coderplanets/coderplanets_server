defmodule GroupherServer.Test.CMS.Artilces.RadarPin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, radar} = CMS.create_article(community, :radar, mock_attrs(:radar), user)

    {:ok, ~m(user community radar)a}
  end

  describe "[cms radar pin]" do
    test "can pin a radar", ~m(community radar)a do
      {:ok, _} = CMS.pin_article(:radar, radar.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{radar_id: radar.id})

      assert pind_article.radar_id == radar.id
    end

    test "one community & thread can only pin certern count of radar", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_radar} = CMS.create_article(community, :radar, mock_attrs(:radar), user)
        {:ok, _} = CMS.pin_article(:radar, new_radar.id, community.id)
        acc
      end)

      {:ok, new_radar} = CMS.create_article(community, :radar, mock_attrs(:radar), user)
      {:error, reason} = CMS.pin_article(:radar, new_radar.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit radar", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:radar, 8848, community.id)
    end

    test "can undo pin to a radar", ~m(community radar)a do
      {:ok, _} = CMS.pin_article(:radar, radar.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:radar, radar.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{radar_id: radar.id})
    end
  end
end
