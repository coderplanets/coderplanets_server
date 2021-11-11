defmodule GroupherServer.Test.Mutation.Articles.Works do
  use GroupherServer.TestTools

  import Helper.Utils, only: [keys_to_atoms: 1, camelize_map_key: 1]
  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias CMS.Model.Works
  alias Accounts.Model.User

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community, %{raw: "home"})

    works_attrs = mock_attrs(:works, %{community_id: community.id})
    {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, works)

    {:ok, ~m(user_conn user user2 guest_conn owner_conn community works)a}
  end

  describe "[mutation works curd]" do
    @create_works_query """
    mutation (
      $cover: String!,
      $title: String!,
      $desc: String!,
      $homeLink: String!,
      $body: String!,
      $communityId: ID!,
      $profitMode: ProfitMode,
      $workingMode: WorkingMode,
      $cities: [String],
      $techstacks: [String],
      $teammates: [String],
      $socialInfo: [SocialInfo],
      $appStore: [AppStoreInfo],
      $articleTags: [Id]
     ) {
      createWorks(
        cover: $cover,
        title: $title,
        desc: $desc,
        homeLink: $homeLink,
        body: $body,
        communityId: $communityId,
        profitMode: $profitMode,
        workingMode: $workingMode,
        cities: $cities,
        techstacks: $techstacks,
        teammates: $teammates,
        socialInfo: $socialInfo,
        appStore: $appStore,
        articleTags: $articleTags
        ) {
          id
          title
          cover
          desc
          homeLink
          profitMode
          workingMode
          cities {
            title
            logo
            raw
          }
          techstacks {
            title
            desc
            logo
          }
          teammates {
            login
            nickname
            avatar
          }
          socialInfo {
            platform
            link
          }
          appStore {
            platform
            link
          }
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
    test "create works with valid attrs and make sure author exsit", ~m(community user2)a do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      works_attr =
        mock_attrs(:works, %{
          cover: "cool cover",
          desc: "cool works",
          homeLink: "homeLink",
          profitMode: "FREE",
          workingMode: "FULLTIME",
          cities: ["chengdu", "xiamen"],
          techstacks: ["elixir", "React"],
          teammates: [user.login, user2.login],
          socialInfo: [
            %{
              platform: "TWITTER",
              link: "https://twitter.com/xxx"
            },
            %{
              platform: "GITHUB",
              link: "https://github.com/xxx"
            }
          ],
          appStore: [
            %{
              platform: "apple",
              link: "https://apple.com/xxx"
            },
            %{
              platform: "others",
              link: "https://others.com/xxx"
            }
          ]
        })

      variables = works_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_works_query, variables, "createWorks")

      {:ok, found} = ORM.find(Works, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["desc"] == "cool works"
      assert created["cover"] == "cool cover"
      assert created["homeLink"] == "homeLink"

      assert created["teammates"] |> length == 2
      assert user_exist_in?(user, created["teammates"])
      assert user_exist_in?(user2, created["teammates"])

      assert created["profitMode"] == "FREE"
      assert created["workingMode"] == "FULLTIME"
      assert created["originalCommunity"]["id"] == to_string(community.id)
      assert not is_nil(created["cities"])
      assert not is_nil(created["techstacks"])
      assert not is_nil(created["socialInfo"])
      assert not is_nil(created["appStore"])

      assert created["id"] == to_string(found.id)

      {:ok, user} = ORM.find(User, user.id)
      {:ok, user2} = ORM.find(User, user2.id)

      assert user.meta.is_maker
      assert user2.meta.is_maker
    end

    test "create works with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)

      works_attr = mock_attrs(:works)

      variables =
        works_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_works_query, variables, "createWorks")

      {:ok, works} = ORM.find(Works, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, works.article_tags)
    end

    test "create works should excape xss attracts", ~m(community)a do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      works_attr = mock_attrs(:works, %{body: mock_xss_string()})
      variables = works_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_works_query, variables, "createWorks")

      {:ok, works} = ORM.find(Works, result["id"], preload: :document)
      body_html = works |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create works should excape xss attracts 2", ~m(community)a do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      works_attr = mock_attrs(:works, %{body: mock_xss_string(:safe)})
      variables = works_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_works_query, variables, "createWorks")
      {:ok, works} = ORM.find(Works, result["id"], preload: :document)
      body_html = works |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    @query """
    mutation(
      $id: ID!,
      $title: String,
      $body: String,
      $profitMode: ProfitMode,
      $workingMode: WorkingMode,
      $cities: [String],
      $techstacks: [String],
      $socialInfo: [SocialInfo],
      $appStore: [AppStoreInfo],
      $articleTags: [Ids]
    ){
      updateWorks(
        id: $id,
        title: $title,
        body: $body,
        profitMode: $profitMode,
        workingMode: $workingMode,
        cities: $cities,
        techstacks: $techstacks,
        socialInfo: $socialInfo,
        appStore: $appStore,
        articleTags: $articleTags
      ) {
        id
        title
        profitMode
        workingMode
        cities {
          title
          logo
          raw
        }
        techstacks {
          title
          desc
          logo
        }
        socialInfo {
          platform
          link
        }
        appStore {
          platform
          link
        }
        document {
          bodyHtml
        }
        articleTags {
          id
        }
      }
    }
    """
    test "works can be update by owner", ~m(owner_conn works)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: works.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}"),
        profitMode: "FREE",
        workingMode: "FULLTIME",
        cities: ["chengdu", "xiamen"],
        techstacks: ["elixir", "React"],
        socialInfo: [
          %{
            platform: "TWITTER",
            link: "https://twitter.com/xxx"
          },
          %{
            platform: "GITHUB",
            link: "https://github.com/xxx"
          }
        ],
        appStore: [
          %{
            platform: "apple",
            link: "https://apple.com/xxx"
          },
          %{
            platform: "others",
            link: "https://others.com/xxx"
          }
        ]
      }

      result = owner_conn |> mutation_result(@query, variables, "updateWorks")

      assert result["title"] == variables.title
      assert result["appStore"] |> Enum.map(&keys_to_atoms(&1)) == variables.appStore
      assert result["socialInfo"] |> Enum.map(&keys_to_atoms(&1)) == variables.socialInfo
      assert result["profitMode"] == variables.profitMode
      assert result["workingMode"] == variables.workingMode

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))
    end

    test "update a works without login user fails", ~m(guest_conn works)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: works.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "login user with auth passport update a works", ~m(works)a do
      works = works |> Repo.preload(:communities)

      works_communities_0 = works.communities |> List.first() |> Map.get(:title)
      passport_rules = %{works_communities_0 => %{"works.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: works.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateWorks")

      assert updated["id"] == to_string(works.id)
    end

    test "unauth user update works fails", ~m(user_conn guest_conn works)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: works.id,
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
      deleteWorks(id: $id) {
        id
      }
    }
    """

    test "can delete a works by works's owner", ~m(owner_conn works)a do
      deleted = owner_conn |> mutation_result(@query, %{id: works.id}, "deleteWorks")

      assert deleted["id"] == to_string(works.id)
      assert {:error, _} = ORM.find(Works, deleted["id"])
    end

    test "can delete a works by auth user", ~m(works)a do
      works = works |> Repo.preload(:communities)
      belongs_community_title = works.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"works.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: works.id}, "deleteWorks")

      assert deleted["id"] == to_string(works.id)
      assert {:error, _} = ORM.find(Works, deleted["id"])
    end
  end
end
