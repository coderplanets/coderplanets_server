defmodule GroupherServer.CMS.Embeds.AbuseReportUser do
  @moduledoc """
  abuse report user
  """
  use Ecto.Schema

  alias CMS.Embeds

  embedded_schema do
    field(:reason, :string)
    field(:additional_reason, :string)
    embeds_one(:user, Embeds.User, on_replace: :delete)

    timestamps(type: :utc_datetime)
  end
end
