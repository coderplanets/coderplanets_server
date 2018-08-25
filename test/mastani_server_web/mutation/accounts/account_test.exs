defmodule MastaniServer.Test.Mutation.Account.Basic do
  use MastaniServer.TestTools

  # alias MastaniServer.{Accounts}
  # alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account update]" do
    @update_query """
    mutation($profile: UserProfileInput!) {
      updateProfile(profile: $profile) {
        id
        nickname
        education_backgrounds {
          school
          major
        }
        work_backgrounds {
          company
          title
        }
      }
    }
    """
    test "user can update it's own profile", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname"
        }
      }

      updated = ownd_conn |> mutation_result(@update_query, variables, "updateProfile")

      assert updated["nickname"] == "new nickname"
    end

    @tag :wip
    test "user can update it's own education_backgrounds", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname",
          education_backgrounds: [
            %{
              school: "school",
              major: "bad ass"
            },
            %{
              school: "school2",
              major: "bad ass2"
            }
          ]
        }
      }

      # assert ownd_conn |> mutation_get_error?(@update_query, variables)

      updated = ownd_conn |> mutation_result(@update_query, variables, "updateProfile")
      assert updated["nickname"] == "new nickname"

      assert updated["education_backgrounds"] |> is_list
      assert updated["education_backgrounds"] |> length == 2
      assert updated["education_backgrounds"] |> Enum.any?(&(&1["school"] == "school"))
      assert updated["education_backgrounds"] |> Enum.any?(&(&1["major"] == "bad ass"))
    end

    @tag :wip
    test "user update education_backgrounds with invalid data fails", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname",
          education_backgrounds: [
            %{
              major: "bad ass2"
            },
            %{
              school: "school2",
              major: "bad ass2"
            }
          ]
        }
      }

      assert ownd_conn |> mutation_get_error?(@update_query, variables)
    end

    @tag :wip
    test "user can update it's own work backgrounds", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname",
          work_backgrounds: [
            %{
              company: "company",
              title: "bad ass"
            },
            %{
              company: "company 2",
              title: "bad ass2"
            }
          ]
        }
      }

      # assert ownd_conn |> mutation_get_error?(@update_query, variables)

      updated = ownd_conn |> mutation_result(@update_query, variables, "updateProfile")
      assert updated["nickname"] == "new nickname"

      assert updated["work_backgrounds"] |> is_list
      assert updated["work_backgrounds"] |> length == 2
      assert updated["work_backgrounds"] |> Enum.any?(&(&1["company"] == "company"))
      assert updated["work_backgrounds"] |> Enum.any?(&(&1["title"] == "bad ass"))
    end

    @tag :wip
    test "user update work backgrounds with invalid data fails", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname",
          work_backgrounds: [
            %{
              title: "bad ass2"
            },
            %{
              company: "school2",
              title: "bad ass2"
            }
          ]
        }
      }

      assert ownd_conn |> mutation_get_error?(@update_query, variables)
    end

    test "user's profile can not updated by guest", ~m(guest_conn)a do
      variables = %{
        profile: %{
          nickname: "new nickname"
        }
      }

      assert guest_conn |> mutation_get_error?(@update_query, variables, ecode(:account_login))
    end
  end
end
