defmodule MastaniServer.Test.CMS.JobReactions do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user community job_attrs)a}
  end

  describe "[cms job star/favorite reaction]" do
    test "star and undo star reaction to job", ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, _} = CMS.reaction(:job, :star, job.id, user)
      {:ok, reaction_users} = CMS.reaction_users(:job, :star, job.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      {:ok, _} = CMS.undo_reaction(:job, :star, job.id, user)
      {:ok, reaction_users2} = CMS.reaction_users(:job, :star, job.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end

    test "favorite and undo favorite reaction to job", ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, _} = CMS.reaction(:job, :favorite, job.id, user)
      {:ok, reaction_users} = CMS.reaction_users(:job, :favorite, job.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      {:ok, _} = CMS.undo_reaction(:job, :favorite, job.id, user)
      {:ok, reaction_users2} = CMS.reaction_users(:job, :favorite, job.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end
  end
end
