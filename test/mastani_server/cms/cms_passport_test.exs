defmodule MastaniServer.Test.CMSPassportTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  alias MastaniServer.CMS
  alias MastaniServer.Accounts.User

  setup do
    {:ok, [user, user2]} = db_insert_multi(:user, 2)
    {:ok, ~m(user user2)a}
  end

  describe "[cms_passports]" do
    @valid_passport_rules %{
      "js" => %{
        "post.article.delete" => true,
        "post.tag.edit" => true
      }
    }
    @valid_passport_rules2 %{
      "js" => %{
        "post.article.delete" => false,
        "post.tag.edit" => true
      }
    }
    test "can insert valid nested passport stucture", ~m(user)a do
      {:ok, passport} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)

      assert passport.user_id == user.id
      assert passport.rules |> get_in(["js", "post.article.delete"]) == true
      assert passport.rules |> get_in(["js", "post.tag.edit"]) == true
    end

    test "can update valid nested passport stucture", ~m(user)a do
      {:ok, passport} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)

      assert passport.rules |> get_in(["js", "post.article.delete"]) == true
      assert passport.rules |> get_in(["js", "post.tag.edit"]) == true

      valid_passport2 = %{
        "js" => %{
          "post.tag.edit" => false
        }
      }

      {:ok, updated_passport} = CMS.stamp_passport(%User{id: user.id}, valid_passport2)

      assert updated_passport.user_id == user.id
      assert updated_passport.rules |> get_in(["js", "post.article.delete"]) == true
      assert updated_passport.rules |> get_in(["js", "post.tag.edit"]) == false
    end

    test "get a user's passport", ~m(user)a do
      {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      {:ok, passport} = CMS.get_passport(%User{id: user.id})
      # IO.inspect(passport, label: "what passport")

      assert passport |> Map.equal?(@valid_passport_rules)
    end

    test "get a normal user's passport fails", ~m(user)a do
      # {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      assert {:error, _} = CMS.get_passport(%User{id: user.id})
    end

    test "get a non-exsit user's passport fails" do
      assert {:error, _} = CMS.get_passport(%User{id: non_exsit_id()})
    end

    test "list passport by key", ~m(user user2)a do
      {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      {:ok, _} = CMS.stamp_passport(%User{id: user2.id}, @valid_passport_rules2)

      {:ok, passports} = CMS.list_passports("js", "post.article.delete")
      assert length(passports) == 1
      assert passports |> List.first() |> Map.get(:rules) |> Map.equal?(@valid_passport_rules)
    end

    test "list passport by invalid key get []", ~m(user)a do
      {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      {:ok, []} = CMS.list_passports("js", "non-exsit")

      {:ok, []} = CMS.list_passports("non-exsit", "non-exsit")
    end

    test "can ease a rule in passport", ~m(user)a do
      {:ok, passport} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)
      assert passport.rules |> get_in(["js", "post.article.delete"]) == true

      {:ok, passport_after} =
        CMS.erase_passport(%User{id: user.id}, ["js", "post.article.delete"])

      assert nil == passport_after.rules |> get_in(["js", "post.article.delete"])
    end

    test "ease a no-exsit rule in passport fails", ~m(user)a do
      {:ok, _} = CMS.stamp_passport(%User{id: user.id}, @valid_passport_rules)

      {:error, _} = CMS.erase_passport(%User{id: user.id}, ["js", "non-exsit"])
      {:error, _} = CMS.erase_passport(%User{id: user.id}, ["non-exsit", "post.article.delete"])
      {:error, _} = CMS.erase_passport(%User{id: user.id}, ["non-exsit", "non-exsit"])
    end
  end
end
