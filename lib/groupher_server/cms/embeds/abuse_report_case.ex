defmodule GroupherServer.CMS.Embeds.AbuseReportCase do
  @moduledoc """
  abuse report user
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.Embeds

  embedded_schema do
    field(:reason, :string)
    field(:additional_reason, :string)
    embeds_one(:user, Embeds.User, on_replace: :delete)

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:reason, :additional_reason])
    |> cast_embed(:user, required: true, with: &Embeds.User.changeset/2)
  end
end
