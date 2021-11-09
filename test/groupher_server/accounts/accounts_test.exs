defmodule GroupherServer.Test.Accounts do
  use GroupherServer.TestTools
  # TODO import Service.Utils move both helper and github
  import Helper.Utils

  alias Helper.{Guardian, ORM}
  alias GroupherServer.Accounts

  alias Accounts.Model.User

  # @valid_user mock_attrs(:user)
  @valid_github_profile mock_attrs(:github_profile) |> map_key_stringify

  describe "[update user]" do
    test "update user with valid attrs" do
      {:ok, user} = db_insert(:user)

      attrs = %{
        nickname: "new nickname",
        sex: "dude",
        bio: "new bio",
        shortbio: "new shortbio",
        email: "new@qq.com"
      }

      {:ok, updated} = Accounts.update_profile(%User{id: user.id}, attrs)

      assert updated.bio == attrs.bio
      assert updated.nickname == attrs.nickname
      assert updated.shortbio == attrs.shortbio
      assert updated.sex == attrs.sex
    end

    test "update user social fields with valid attrs" do
      {:ok, user} = db_insert(:user)

      attrs = %{
        location: "new name",
        social: %{
          github: "github addr",
          blog: "my blog",
          company: "my company",
          twitter: "twitter addr"
        }
      }

      {:ok, updated} = Accounts.update_profile(%User{id: user.id}, attrs)

      assert updated.location == "new name"

      assert updated.social.github == attrs.social.github
      assert updated.social.twitter == attrs.social.twitter

      assert updated.social.company == attrs.social.company
      assert updated.social.blog == attrs.social.blog
    end

    test "update user education backgorunds with valid attrs" do
      {:ok, user} = db_insert(:user)

      attrs = %{
        nickname: "new name",
        education_backgrounds: [
          # %{major: "bad ass"},
          %{school: "school", major: "bad ass"},
          %{school: "school2", major: "still bad ass"}
        ]
      }

      {:ok, updated} = Accounts.update_profile(%User{id: user.id}, attrs)

      assert updated.nickname == "new name"
      assert updated.education_backgrounds |> is_list
      assert updated.education_backgrounds |> length == 2
      assert updated.education_backgrounds |> Enum.any?(&(&1.school == "school"))
      assert updated.education_backgrounds |> Enum.any?(&(&1.major == "bad ass"))
    end

    test "update user work backgorunds with valid attrs" do
      {:ok, user} = db_insert(:user)

      attrs = %{
        nickname: "new name",
        work_backgrounds: [
          # %{major: "bad ass"},
          %{company: "company", title: "bad ass"},
          %{company: "company 2", title: "still bad ass"}
        ]
      }

      {:ok, updated} = Accounts.update_profile(%User{id: user.id}, attrs)

      assert updated.nickname == "new name"
      assert updated.work_backgrounds |> is_list
      assert updated.work_backgrounds |> length == 2
      assert updated.work_backgrounds |> Enum.any?(&(&1.company == "company"))
      assert updated.work_backgrounds |> Enum.any?(&(&1.title == "bad ass"))
    end
  end

  describe "[github login]" do
    alias Accounts.Model.{GithubUser, User}

    test "register a valid github user with non-exist in db" do
      assert {:error, _} =
               ORM.find_by(GithubUser, github_id: to_string(@valid_github_profile["id"]))

      assert {:error, _} = ORM.find_by(User, nickname: @valid_github_profile["login"])

      {:ok, %{token: token, user: user}} = Accounts.github_signin(@valid_github_profile)
      {:ok, claims, _info} = Guardian.jwt_decode(token)

      {:ok, created_user} = ORM.find(User, claims.id)

      assert user.id == created_user.id
      assert created_user.login == @valid_github_profile["login"] |> String.downcase()
      assert created_user.nickname == @valid_github_profile["login"]
      assert created_user.avatar == @valid_github_profile["avatar_url"]
      assert created_user.bio == @valid_github_profile["bio"]
      assert created_user.email == @valid_github_profile["email"]

      company_title = created_user.work_backgrounds |> List.first() |> Map.get(:company)
      assert company_title == @valid_github_profile["company"]

      assert created_user.location == @valid_github_profile["location"]
      assert created_user.from_github == true

      {:ok, g_user} = ORM.find_by(GithubUser, github_id: to_string(@valid_github_profile["id"]))

      assert g_user.login == @valid_github_profile["login"]
      assert g_user.avatar_url == @valid_github_profile["avatar_url"]
      assert g_user.access_token == @valid_github_profile["access_token"]
      assert g_user.node_id == @valid_github_profile["node_id"]
    end

    test "new user have a empty achievement" do
      assert {:error, _} =
               ORM.find_by(GithubUser, github_id: to_string(@valid_github_profile["id"]))

      assert {:error, _} = ORM.find_by(User, nickname: @valid_github_profile["login"])

      {:ok, %{token: token, user: _user}} = Accounts.github_signin(@valid_github_profile)
      {:ok, claims, _info} = Guardian.jwt_decode(token)

      {:ok, created_user} = ORM.find(User, claims.id, preload: [:achievement, :social])
      assert is_nil(created_user.social.github) == false

      achievement = created_user.achievement
      assert achievement.user_id == created_user.id
      assert achievement.reputation == 0
      assert achievement.articles_collects_count == 0
      assert achievement.articles_upvotes_count == 0
      assert achievement.source_contribute.h5 == false
      assert achievement.source_contribute.web == false
      assert achievement.source_contribute.we_app == false
      assert achievement.source_contribute.mobile == false
    end

    test "exsit github user created twice fails" do
      assert {:ok, 0} == ORM.count(GithubUser)
      {:ok, _} = Accounts.github_signin(@valid_github_profile)
      assert {:ok, 1} == ORM.count(GithubUser)
      {:ok, _} = Accounts.github_signin(@valid_github_profile)
      assert {:ok, 1} == ORM.count(GithubUser)
    end

    test "github signin user should not locate geo city info" do
      {:ok, guser} = Accounts.github_signin(@valid_github_profile)
      {:ok, user} = ORM.find(User, guser.user.id)

      assert user.geo_city === nil
    end
  end
end
