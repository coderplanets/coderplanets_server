defmodule GroupherServer.Test.Mutation.Account.Basic do
  use GroupherServer.TestTools

  # alias GroupherServer.{Accounts}
  # alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  # describe "[oauth signin]" do
  #   @github_sigin_query """
  #   mutation($code: String!) {
  #     githubSignin(code: $code) {
  #       token
  #       user {
  #         login
  #       }
  #     }
  #   }
  #   """
  #   test "github signin should work", ~m(guest_conn)a do
  #     variables = %{
  #       code: "e2f03e0a9de4284d49ac"
  #     }

  #     ret = guest_conn |> mutation_result(@github_sigin_query, variables, "githubSignin")
  #   end
  # end

  describe "[account update]" do
    @update_query """
    mutation(
      $profile: UserProfileInput!,
      $social: SocialInput,
      $educationBackgrounds: [EduBackgroundInput],
      $workBackgrounds: [WorkBackgroundInput]
    ) {
      updateProfile(
        profile: $profile,
        social: $social,
        educationBackgrounds: $educationBackgrounds,
        workBackgrounds: $workBackgrounds,
      ) {
        id
        avatar
        nickname
        social {
          zhihu
          github
          blog
          twitter
          company
        }
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
          avatar: "new avatar",
          nickname: "new nickname",
          bio: "everyday is the opportunity you don't get back,  so live life to the fullest",
          location: "china |> chengDu (成都).",
          sex: "dude"
        },
        social: %{
          zhihu: "xieyiming-75",
          github: "mydearxym",
          twitter: "fe2",
          blog: "hello",
          company: "world"
        }
      }

      updated = ownd_conn |> mutation_result(@update_query, variables, "updateProfile")

      assert updated["avatar"] == "new avatar"
      assert updated["nickname"] == "new nickname"
      assert updated["social"]["zhihu"] == variables.social.zhihu
      assert updated["social"]["github"] == variables.social.github
      assert updated["social"]["twitter"] == variables.social.twitter
      assert updated["social"]["blog"] == variables.social.blog
      assert updated["social"]["company"] == variables.social.company
    end

    test "user can update it's own backgrounds", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname"
        },
        educationBackgrounds: [
          %{
            school: "school",
            major: "bad ass"
          },
          %{
            school: "school2",
            major: "bad ass2"
          }
        ],
        workBackgrounds: [
          %{
            company: "cps",
            title: "CTO"
          }
        ]
      }

      updated = ownd_conn |> mutation_result(@update_query, variables, "updateProfile")
      assert updated["nickname"] == "new nickname"

      assert updated["education_backgrounds"] |> is_list
      assert updated["education_backgrounds"] |> length == 2
      assert updated["education_backgrounds"] |> Enum.any?(&(&1["school"] == "school"))
      assert updated["education_backgrounds"] |> Enum.any?(&(&1["major"] == "bad ass"))

      assert updated["work_backgrounds"] |> is_list
      assert updated["work_backgrounds"] |> length == 1
      assert updated["work_backgrounds"] |> Enum.any?(&(&1["company"] == "cps"))
      assert updated["work_backgrounds"] |> Enum.any?(&(&1["title"] == "CTO"))
    end

    test "user update education_backgrounds with invalid data fails", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname"
        },
        educationBackgrounds: [
          %{
            major: "bad ass2"
          },
          %{
            school: "school2",
            major: "bad ass2"
          }
        ]
      }

      assert ownd_conn |> mutation_get_error?(@update_query, variables)
    end

    test "user update work backgrounds with invalid data fails", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname"
        },
        workBackgrounds: [
          %{
            title: "bad ass2"
          },
          %{
            company: "school2",
            title: "bad ass2"
          }
        ]
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
