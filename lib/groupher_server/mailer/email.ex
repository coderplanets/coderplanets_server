defmodule GroupherServer.Email do
  @moduledoc """
  the email staff for Groupher
  """
  import Bamboo.Email
  import Helper.Utils, only: [get_config: 2]

  @support_email get_config(:system_emails, :support)

  def welcome_email do
    base_mail()
    |> to("mydearxym@gmail.com")
    |> subject("我是 coderplanets 的邮哥")
    |> html_body("<h2>欢迎你注册  cps support debug x</h2>")
    |> text_body("欢迎你注册  cps")
  end

  defp base_mail do
    new_email()
    |> from(@support_email)
  end
end
