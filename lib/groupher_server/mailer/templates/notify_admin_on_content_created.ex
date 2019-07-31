defmodule GroupherServer.Email.Templates.NotifyAdminOnContentCreated do
  @moduledoc """
  template for notify admin when there is new content created, like but not limit
  to: post, job, video, repo ...

  if you want change style or debug the template
  just copy and paste raw string to: https://mjml.io/try-it-live
  """
  def html(record) do
    """
    hello
    """
  end

  def text() do
    """
    有人打赏了
    """
  end

  defp raw() do
    """
    TODO
    """
  end
end
