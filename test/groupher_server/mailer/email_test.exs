defmodule GroupherServer.Test.Mailer do
  @moduledoc """
  mailer test, see details: https://github.com/thoughtbot/bamboo
  """
  use GroupherServer.TestTools
  use Bamboo.Test

  import Helper.Utils, only: [get_config: 2]
  @support_email get_config(:system_emails, :support_email)

  describe "basic email" do
    test "send welcome email when user has email addr" do
      {:ok, user} = db_insert(:user, %{email: "fake@gmail.com"})

      expected_email = GroupherServer.Email.welcome(user)

      {_, from_addr} = expected_email.from
      [nil: to_addr] = expected_email.to

      assert String.contains?(from_addr, @support_email)
      assert String.contains?(to_addr, user.email)

      assert_delivered_email(expected_email)
    end

    test "not send welcome email when user has no email addr" do
      {:ok, user} = db_insert(:user, %{email: nil})

      expected_email = GroupherServer.Email.welcome(user)
      assert {:ok, :pass} = expected_email
    end
  end
end
