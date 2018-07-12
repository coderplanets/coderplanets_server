defmodule MastaniServer.Test.AccountsTest do
  use MastaniServer.TestTools

  # TODO import Service.Utils move both helper and github
  import Helper.Utils

  alias MastaniServer.Accounts
  alias Helper.{Guardian, ORM}

  # @valid_user mock_attrs(:user)
  @valid_github_profile mock_attrs(:github_profile) |> map_key_stringify

  describe "[update user]" do
    alias Accounts.User

    test "update user with valid attrs" do
      {:ok, user} = db_insert(:user)

      attrs = %{
        nickname: "new nickname",
        sex: "dude",
        bio: "new bio",
        email: "new@qq.com",
        company: "at home",
        qq: "8384384483",
        weibo: "8384",
        weichat: "8384"
      }

      {:ok, updated} = Accounts.update_profile(%User{id: user.id}, attrs)

      assert updated.bio == attrs.bio
      assert updated.nickname == attrs.nickname
      assert updated.sex == attrs.sex
    end

    test "update user with invalid attrs fails" do
      {:ok, user} = db_insert(:user)

      assert {:error, _} = Accounts.update_profile(%User{id: user.id}, %{qq: "123"})
      assert {:error, _} = Accounts.update_profile(%User{id: user.id}, %{sex: "other"})
      assert {:error, _} = Accounts.update_profile(%User{id: user.id}, %{email: "other"})
    end
  end

  describe "[github login]" do
    alias Accounts.{User, GithubUser}

    test "register a valid github user with non-exist in db" do
      assert {:error, _} =
               ORM.find_by(GithubUser, github_id: to_string(@valid_github_profile["id"]))

      assert {:error, _} = ORM.find_by(User, nickname: @valid_github_profile["login"])

      {:ok, %{token: token, user: user}} = Accounts.github_signin(@valid_github_profile)
      {:ok, claims, _info} = Guardian.jwt_decode(token)

      {:ok, created_user} = ORM.find(User, claims.id)

      assert user.id == created_user.id
      assert created_user.nickname == @valid_github_profile["login"]
      assert created_user.avatar == @valid_github_profile["avatar_url"]
      assert created_user.bio == @valid_github_profile["bio"]

      assert created_user.email == @valid_github_profile["email"]
      assert created_user.company == @valid_github_profile["company"]
      assert created_user.location == @valid_github_profile["location"]
      assert created_user.from_github == true

      {:ok, g_user} = ORM.find_by(GithubUser, github_id: to_string(@valid_github_profile["id"]))

      assert g_user.login == @valid_github_profile["login"]
      assert g_user.avatar_url == @valid_github_profile["avatar_url"]
      assert g_user.access_token == @valid_github_profile["access_token"]
      assert g_user.node_id == @valid_github_profile["node_id"]
    end

    test "exsit github user should not be created twice" do
      assert ORM.count(GithubUser) == 0
      {:ok, _} = Accounts.github_signin(@valid_github_profile)
      assert ORM.count(GithubUser) == 1
      {:ok, _} = Accounts.github_signin(@valid_github_profile)
      assert ORM.count(GithubUser) == 1
    end
  end
end
