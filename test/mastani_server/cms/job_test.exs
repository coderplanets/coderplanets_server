defmodule MastaniServer.Test.JobTest do
  use MastaniServer.TestTools

  alias MastaniServer.{CMS, Accounts}
  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user job_attrs)a}
  end

  describe "[cms jobs curd]" do
    test "can create a job with valid attrs", ~m(user job_attrs)a do
      {:ok, job} = CMS.create_content(:job, %Accounts.User{id: user.id}, job_attrs)

      {:ok, found} = ORM.find(CMS.Job, job.id)
      assert found.id == job.id
      assert found.title == job.title
    end

    test "create job with on exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:job, %{community_id: non_exsit_id()})

      assert {:error, _} = CMS.create_content(:job, %Accounts.User{id: user.id}, invalid_attrs)
    end
  end
end
