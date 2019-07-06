defmodule GroupherServer.Test.Mailer do
  @moduledoc """
  mailer test, see details: https://github.com/thoughtbot/bamboo 
  """
  use GroupherServer.TestTools
  use Bamboo.Test

  import Helper.Utils, only: [get_config: 2]
  @support_email get_config(:system_emails, :support)

  describe "basic email" do
    @tag :wip
    test "welcome email" do
      # user = {"Ralph", "ralph@example.com"}
      expected_email = GroupherServer.Email.welcome_email()
      # assert email.to == user
      assert expected_email.from == @support_email
      # assert email.html_body =~ "<strong>Thanks for joining!</strong>"
      # assert email.text_body =~ "Thanks for joining!"

      expected_email |> GroupherServer.Mailer.deliver_now()
      assert_delivered_email(expected_email)
    end
  end
end
