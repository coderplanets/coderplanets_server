defmodule GroupherServer.Test.Mutation.Articles.Job do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.Job

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})
    {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, job)

    {:ok, ~m(user_conn guest_conn owner_conn user community job)a}
  end

  describe "[mutation job curd]" do
    @create_job_query """
    mutation (
      $title: String!,
      $body: String!,
      $communityId: ID!,
      $company: String!,
      $companyLink: String,
      $articleTags: [Id]
     ) {
      createJob(
        title: $title,
        body: $body,
        communityId: $communityId,
        company: $company,
        companyLink: $companyLink,
        articleTags: $articleTags
        ) {
          id
          title
          document {
            bodyHtml
          }
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

      {:ok, found} = ORM.find(Job, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert created["id"] == to_string(found.id)
    end

    test "create job with valid tags id list.", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :job, article_tag_attrs, user)

      job_attr = mock_attrs(:job)

      variables =
        job_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_job_query, variables, "createJob")
      {:ok, job} = ORM.find(Job, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, job.article_tags)
    end

    test "create job should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      job_attr = mock_attrs(:job, %{body: mock_xss_string()})
      variables = job_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_job_query, variables, "createJob")
      {:ok, job} = ORM.find(Job, result["id"], preload: :document)

      body_html = job |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create job should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      job_attr = mock_attrs(:job, %{body: mock_xss_string(:safe)})
      variables = job_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_job_query, variables, "createJob")

      {:ok, job} = ORM.find(Job, result["id"], preload: :document)
      body_html = job |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $articleTags: [Ids]){
      updateJob(id: $id, title: $title, body: $body, articleTags: $articleTags) {
        id
        title
        document {
          bodyHtml
        }
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
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "job can be update by owner", ~m(owner_conn job)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: job.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      result = owner_conn |> mutation_result(@query, variables, "updateJob")

      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))
    end

    test "login user with auth passport update a job", ~m(job)a do
      job = job |> Repo.preload(:communities)

      job_communities_0 = job.communities |> List.first() |> Map.get(:title)
      passport_rules = %{job_communities_0 => %{"job.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: job.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateJob")

      assert updated["id"] == to_string(job.id)
    end

    test "unauth user update job fails", ~m(user_conn guest_conn job)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: job.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
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
      assert {:error, _} = ORM.find(Job, deleted["id"])
    end

    test "can delete a job by auth user", ~m(job)a do
      job = job |> Repo.preload(:communities)
      belongs_community_title = job.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"job.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: job.id}, "deleteJob")

      assert deleted["id"] == to_string(job.id)
      assert {:error, _} = ORM.find(Job, deleted["id"])
    end
  end
end
