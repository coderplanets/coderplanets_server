defmodule GroupherServer.Email do
  @moduledoc """
  the email dispatch system for Groupher

  welcom_email -> send to new register
  """
  import Bamboo.Email
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{Accounts, Billing, Email, Mailer}

  alias Accounts.Model.User
  alias Billing.Model.BillRecord
  alias Email.Templates
  alias Mailer

  @support_email get_config(:system_emails, :support_email)
  @admin_email get_config(:system_emails, :admin_email)

  @conf_welcome_new_register get_config(:system_emails, :welcome_new_register)
  @conf_notify_admin_on_new_user get_config(:system_emails, :notify_admin_on_new_user)
  @conf_notify_admin_on_content_created get_config(
                                          :system_emails,
                                          :notify_admin_on_content_created
                                        )

  def welcome(%User{email: email} = user) when not is_nil(email) do
    case @conf_welcome_new_register do
      true ->
        base_mail()
        |> to(email)
        |> subject("欢迎来到 coderplanets")
        |> html_body(Templates.Welcome.html(user))
        |> text_body(Templates.Welcome.text())
        |> Mailer.deliver_later()

      false ->
        {:ok, :pass}
    end
  end

  #  user has no email log to somewhere
  def welcome(_user) do
    {:ok, :pass}
  end

  def thanks_donation(%User{email: email} = user, %BillRecord{} = record) do
    # IO.inspect(email, label: "thanks_donation")

    base_mail()
    |> to(email)
    |> subject("感谢你的打赏")
    |> html_body(Templates.ThanksDonation.html(user, record))
    |> text_body(Templates.ThanksDonation.text())
    |> Mailer.deliver_later()
  end

  #  notify admin when new user register
  def notify_admin(%User{from_github: true} = user, :new_register) do
    case @conf_notify_admin_on_new_user do
      true ->
        base_mail()
        |> to(@admin_email)
        |> subject("新用户(#{user.nickname})注册")
        |> html_body(Templates.NotifyAdminRegister.html(user))
        |> text_body(Templates.NotifyAdminRegister.text())
        |> Mailer.deliver_later()

      false ->
        {:ok, :pass}
    end
  end

  def notify_admin(_user, :new_register) do
    {:ok, :pass}
  end

  #  notify admin when someone donote
  def notify_admin(%BillRecord{} = record, :payment) do
    base_mail()
    |> to(@admin_email)
    |> subject("打赏 #{record.amount} 元")
    |> html_body(Templates.NotifyAdminPayment.html(record))
    |> text_body(Templates.NotifyAdminPayment.text())
    |> Mailer.deliver_later()
  end

  #  notify admin when new post has created
  def notify_admin(%{type: type, title: title} = info, :new_article) do
    case @conf_notify_admin_on_content_created do
      true ->
        base_mail()
        |> to(@admin_email)
        |> subject("new #{type}: #{title}")
        |> html_body(Templates.NotifyAdminOnContentCreated.html(info))
        |> text_body(Templates.NotifyAdminOnContentCreated.text(info))
        |> Mailer.deliver_later()

      false ->
        {:ok, :pass}
    end
  end

  # some one comment to your post ..
  # the author's publish content being deleted ..
  # def notify_author, do: IO.inspect("notify_author")
  # def notify_publish, do: IO.inspect("notify_publish")
  # ...

  defp base_mail do
    new_email()
    |> from(@support_email)
  end
end
