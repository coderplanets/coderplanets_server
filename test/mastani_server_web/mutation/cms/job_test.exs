defmodule MastaniServer.Test.Mutation.Job do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.CMS

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, job)

    {:ok, ~m(user_conn guest_conn owner_conn user job)a}
  end

  describe "[mutation job curd]" do
    @create_job_query """
    mutation (
      $title: String!,
      $body: String!,
      $digest: String!,
      $length: Int!,
      $communityId: ID!,
      $company: String!,
      $companyLogo: String!
      $location: String!,
      $salary: String!,
      $exp: String!,
      $education: String!,
      $finance: String!,
      $scale: String!,
      $field: String!,
      $tags: [Ids]
     ) {
      createJob(
        title: $title,
        body: $body,
        digest: $digest,
        length: $length,
        communityId: $communityId,
        company: $company,
        companyLogo: $companyLogo,
        location: $location,
        salary: $salary,
        exp: $exp,
        education: $education,
        finance: $finance,
        scale: $scale,
        field: $field,
        tags: $tags
        ) {
          id
          title
          body
          salary
          exp
          education
          field
          communities {
            id
            title
          }
      }
    }
    """
    test "create job with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      job_attr = mock_attrs(:job)

      variables = job_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_job_query, variables, "createJob")

      assert created["salary"] == variables["salary"]
      assert created["exp"] == variables["exp"]
      assert created["field"] == variables["field"]
      assert created["education"] == variables["education"]

      {:ok, found} = ORM.find(CMS.Job, created["id"])

      assert created["id"] == to_string(found.id)
    end

    test "can create job with tags" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      job_attr = mock_attrs(:job)

      variables =
        job_attr
        |> Map.merge(%{communityId: community.id})
        |> Map.merge(%{companyLogo: job_attr.company_logo})
        |> Map.merge(%{tags: [%{id: tag1.id}, %{id: tag2.id}]})

      created = user_conn |> mutation_result(@create_job_query, variables, "createJob")
      {:ok, job} = ORM.find(CMS.Job, created["id"], preload: :tags)

      assert job.tags |> Enum.any?(&(&1.id == tag1.id))
      assert job.tags |> Enum.any?(&(&1.id == tag2.id))
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $salary: String){
      updateJob(id: $id, title: $title, body: $body, salary: $salary) {
        id
        title
        body
        salary
      }
    }
    """
    test "update a job without login user fails", ~m(guest_conn job)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: job.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}",
        salary: "15k-20k"
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "job can be update by owner", ~m(owner_conn job)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: job.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}",
        salary: "15k-20k"
      }

      updated = owner_conn |> mutation_result(@query, variables, "updateJob")

      assert updated["title"] == variables.title
      assert updated["body"] == variables.body
      assert updated["salary"] == variables.salary
    end

    test "login user with auth passport update a job", ~m(job)a do
      job_communities_0 = job.communities |> List.first() |> Map.get(:title)
      passport_rules = %{job_communities_0 => %{"job.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: job.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateJob")

      assert updated["id"] == to_string(job.id)
    end

    test "unauth user update job fails", ~m(user_conn guest_conn job)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: job.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      deleteJob(id: $id) {
        id
      }
    }
    """
    test "can delete a job by job's owner", ~m(owner_conn job)a do
      deleted = owner_conn |> mutation_result(@query, %{id: job.id}, "deleteJob")

      assert deleted["id"] == to_string(job.id)
      assert {:error, _} = ORM.find(CMS.Job, deleted["id"])
    end

    test "can delete a job by auth user", ~m(job)a do
      belongs_community_title = job.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"job.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: job.id}, "deleteJob")

      assert deleted["id"] == to_string(job.id)
      assert {:error, _} = ORM.find(CMS.Job, deleted["id"])
    end
  end

  describe "[mutation job tag]" do
    @set_tag_query """
    mutation($thread: String!, $id: ID!, $tagId: ID! $communityId: ID!) {
      setTag(thread: $thread, id: $id, tagId: $tagId, communityId: $communityId) {
        id
        title
      }
    }
    """
    test "auth user can set a valid tag to job", ~m(job)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "job", community: community})

      passport_rules = %{community.title => %{"job.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{thread: "JOB", id: job.id, tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")
      # {:ok, found} = ORM.find(CMS.Job, job.id, preload: :tags)

      # assoc_tags = found.tags |> Enum.map(& &1.id)
      # assert tag.id in assoc_tags
    end

    # TODO: should fix in auth layer
    # test "auth user set a other community's tag to job fails", ~m(job)a do
    # {:ok, community} = db_insert(:community)
    # {:ok, tag} = db_insert(:tag, %{thread: "job"})

    # passport_rules = %{community.title => %{"job.tag.set" => true}}
    # rule_conn = simu_conn(:user, cms: passport_rules)

    # variables = %{thread: "JOB", id: job.id, tagId: tag.id, communityId: community.id}
    # assert rule_conn |> mutation_get_error?(@set_tag_query, variables, ecode(:custom))
    # end

    test "can set multi tag to a job", ~m(job)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{community: community, thread: "job"})
      {:ok, tag2} = db_insert(:tag, %{community: community, thread: "job"})

      passport_rules = %{community.title => %{"job.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{thread: "JOB", id: job.id, tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{thread: "JOB", id: job.id, tagId: tag2.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Job, job.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags
    end
  end
end
