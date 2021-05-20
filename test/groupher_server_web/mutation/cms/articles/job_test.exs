defmodule GroupherServer.Test.Mutation.Articles.Job do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Delivery}

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
      $salary: String!,
      $exp: String!,
      $education: String!,
      $finance: String!,
      $scale: String!,
      $field: String!,
      $mentionUsers: [Ids],
      $articleTags: [Ids]
     ) {
      createJob(
        title: $title,
        body: $body,
        digest: $digest,
        length: $length,
        communityId: $communityId,
        company: $company,
        companyLogo: $companyLogo,
        salary: $salary,
        exp: $exp,
        education: $education,
        finance: $finance,
        scale: $scale,
        field: $field,
        mentionUsers: $mentionUsers,
        articleTags: $articleTags
        ) {
          id
          title
          body
          salary
          exp
          education
          field
          originalCommunity {
            id
          }
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
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert created["id"] == to_string(found.id)
    end

    test "create job should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      job_attr = mock_attrs(:job, %{body: assert_v(:xss_string)})

      variables = job_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      created = user_conn |> mutation_result(@create_job_query, variables, "createJob")
      {:ok, job} = ORM.find(CMS.Job, created["id"])

      assert job.body == assert_v(:xss_safe_string)
    end

    test "can create job with mentionUsers" do
      {:ok, user} = db_insert(:user)
      {:ok, user2} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      job_attr = mock_attrs(:job)

      variables =
        job_attr
        |> camelize_map_key
        |> Map.merge(%{communityId: community.id})
        |> Map.merge(%{mentionUsers: [%{id: user2.id}]})

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      assert mentions.total_count == 0

      _created = user_conn |> mutation_result(@create_job_query, variables, "createJob")

      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      the_mention = mentions.entries |> List.first()

      assert mentions.total_count == 1
      assert the_mention.source_type == "job"
      assert the_mention.read == false
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $salary: String, $articleTags: [Ids]){
      updateJob(id: $id, title: $title, body: $body, salary: $salary, articleTags: $articleTags) {
        id
        title
        body
        salary
        articleTags {
          id
        }
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
end
