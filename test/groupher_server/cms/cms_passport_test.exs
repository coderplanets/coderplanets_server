defmodule GroupherServer.Test.CMS.Passport do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts.Model.User
  alias GroupherServer.CMS

  setup do
    {:ok, [user, user2]} = db_insert_multi(:user, 2)
    {:ok, ~m(user user2)a}
  end

  describe "[cms_passports]" do
    @valid_passport_rules %{
      "javascript" => %{
        "post.article.delete" => true,
        "post.tag.edit" => true
      }
    }
    @valid_passport_rules2 %{
      "javascript" => %{
        "post.article.update" => true,
        "post.tag.edit" => true
      }
    }
    test "can insert valid nested passport stucture", ~m(user)a do
      {:ok, passport} = CMS.stamp_passport(@valid_passport_rules, user)

      assert passport.user_id == user.id
      assert passport.rules |> get_in(["javascript", "post.article.delete"]) == true
      assert passport.rules |> get_in(["javascript", "post.tag.edit"]) == true
    end

    test "false rules will be delete from current passport", ~m(user)a do
      {:ok, passport} = CMS.stamp_passport(@valid_passport_rules, user)

      assert passport.rules |> get_in(["javascript", "post.article.delete"]) == true
      assert passport.rules |> get_in(["javascript", "post.tag.edit"]) == true

      valid_passport2 = %{
        "javascript" => %{
          "post.tag.edit" => false
        }
      }

      {:ok, updated_passport} = CMS.stamp_passport(valid_passport2, user)

      assert updated_passport.user_id == user.id
      assert updated_passport.rules |> get_in(["javascript", "post.article.delete"]) == true
      assert updated_passport.rules |> get_in(["javascript", "post.tag.edit"]) == nil
    end

    test "get a user's passport", ~m(user)a do
      {:ok, _} = CMS.stamp_passport(@valid_passport_rules, user)
      {:ok, passport} = CMS.get_passport(user)

      assert passport |> Map.equal?(@valid_passport_rules)
    end

    test "get a normal user's passport fails", ~m(user)a do
      assert {:ok, %{}} = CMS.get_passport(user)
    end

    test "get a non-exsit user's passport fails" do
      assert {:error, _} = CMS.get_passport(%User{id: non_exsit_id()})
    end

    test "list passport by key", ~m(user user2)a do
      {:ok, _} = CMS.stamp_passport(@valid_passport_rules, user)
      {:ok, _} = CMS.stamp_passport(@valid_passport_rules2, user2)

      {:ok, passports} = CMS.paged_passports("javascript", "post.article.delete")
      assert length(passports) == 1
      assert passports |> List.first() |> Map.get(:rules) |> Map.equal?(@valid_passport_rules)
    end

    test "list passport by invalid key get []", ~m(user)a do
      {:ok, _} = CMS.stamp_passport(@valid_passport_rules, user)
      {:ok, []} = CMS.paged_passports("javascript", "non-exsit")

      {:ok, []} = CMS.paged_passports("non-exsit", "non-exsit")
    end

    test "can ease a rule in passport", ~m(user)a do
      {:ok, passport} = CMS.stamp_passport(@valid_passport_rules, user)
      assert passport.rules |> get_in(["javascript", "post.article.delete"]) == true

      {:ok, passport_after} = CMS.erase_passport(["javascript", "post.article.delete"], user)

      assert nil == passport_after.rules |> get_in(["javascript", "post.article.delete"])
    end

    test "ease a no-exsit rule in passport fails", ~m(user)a do
      {:ok, _} = CMS.stamp_passport(@valid_passport_rules, user)

      {:error, _} = CMS.erase_passport(["javascript", "non-exsit"], user)
      {:error, _} = CMS.erase_passport(["non-exsit", "post.article.delete"], user)
      {:error, _} = CMS.erase_passport(["non-exsit", "non-exsit"], user)
    end
  end
end
