defmodule MastaniServer.Test.CMSPassportTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory

  alias MastaniServer.CMS
  alias MastaniServer.Accounts.User

  @valid_user mock_attrs(:user)
  @invalid_userid 15_982_398_614

  setup do
    {:ok, user} = db_insert(:user, @valid_user)
    {:ok, user2} = db_insert(:user, @valid_user)

    {:ok, user: user, user2: user2}
  end

  describe "[cms_passports]" do
    @valid_passport_rules %{
      "js" => %{
        "post-article-delete" => true,
        "post-tag-edit" => true
      }
    }
    @valid_passport_rules2 %{
      "js" => %{
        "post-article-delete" => false,
        "post-tag-edit" => true
      }
    }
    test "can insert valid nested passport stucture", %{user: user} do
      {:ok, passport} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)

      assert passport.user_id == user.id
      assert passport.rules |> get_in(["js", "post-article-delete"]) == true
      assert passport.rules |> get_in(["js", "post-tag-edit"]) == true
    end

    test "can update valid nested passport stucture", %{user: user} do
      {:ok, passport} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)

      assert passport.rules |> get_in(["js", "post-article-delete"]) == true
      assert passport.rules |> get_in(["js", "post-tag-edit"]) == true

      valid_passport2 = %{
        "js" => %{
          "post-tag-edit" => false
        }
      }

      {:ok, updated_passport} = CMS.stamp_passport(%User{id: user.id}, valid_passport2)

      assert updated_passport.user_id == user.id
      assert updated_passport.rules |> get_in(["js", "post-article-delete"]) == true
      assert updated_passport.rules |> get_in(["js", "post-tag-edit"]) == false
    end

    test "get a user's passport", %{user: user} do
      {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      {:ok, passport} = CMS.get_passport(%User{id: user.id})

      assert passport |> Map.get(:rules) |> Map.equal?(@valid_passport_rules)
    end

    test "get a non-exsit user's passport fails" do
      assert {:error, _} = CMS.get_passport(%User{id: @invalid_userid})
    end

    test "list passport by key", %{user: user, user2: user2} do
      {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      {:ok, _} = CMS.stamp_passport(%User{id: user2.id}, @valid_passport_rules2)

      {:ok, passports} = CMS.list_passports("js", "post-article-delete")
      assert length(passports) == 1
      assert passports |> List.first() |> Map.get(:rules) |> Map.equal?(@valid_passport_rules)
    end

    test "list passport by invalid key get []", %{user: user} do
      {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      {:ok, []} = CMS.list_passports("js", "non-exsit")

      {:ok, []} = CMS.list_passports("non-exsit", "non-exsit")
    end

    test "can ease a rule in passport", %{user: user} do
      {:ok, passport} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      assert passport.rules |> get_in(["js", "post-article-delete"]) == true

      {:ok, passport_after} =
        CMS.erase_passport(%User{id: user.id}, ["js", "post-article-delete"])

      assert nil == passport_after.rules |> get_in(["js", "post-article-delete"])
    end

    test "ease a no-exsit rule in passport fails", %{user: user} do
      {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)

      {:error, _} = CMS.erase_passport(%User{id: user.id}, ["js", "non-exsit"])
      {:error, _} = CMS.erase_passport(%User{id: user.id}, ["non-exsit", "post-article-delete"])
      {:error, _} = CMS.erase_passport(%User{id: user.id}, ["non-exsit", "non-exsit"])
    end
  end
end
