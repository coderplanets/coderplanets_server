defmodule GroupherServer.Test.CMS.Artilces.MeetupPin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, meetup} = CMS.create_article(community, :meetup, mock_attrs(:meetup), user)

    {:ok, ~m(user community meetup)a}
  end

  describe "[cms meetup pin]" do
    test "can pin a meetup", ~m(community meetup)a do
      {:ok, _} = CMS.pin_article(:meetup, meetup.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{meetup_id: meetup.id})

      assert pind_article.meetup_id == meetup.id
    end

    test "one community & thread can only pin certern count of meetup", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_meetup} = CMS.create_article(community, :meetup, mock_attrs(:meetup), user)
        {:ok, _} = CMS.pin_article(:meetup, new_meetup.id, community.id)
        acc
      end)

      {:ok, new_meetup} = CMS.create_article(community, :meetup, mock_attrs(:meetup), user)
      {:error, reason} = CMS.pin_article(:meetup, new_meetup.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit meetup", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:meetup, 8848, community.id)
    end

    test "can undo pin to a meetup", ~m(community meetup)a do
      {:ok, _} = CMS.pin_article(:meetup, meetup.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:meetup, meetup.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{meetup_id: meetup.id})
    end
  end
end
