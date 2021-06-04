defmodule GroupherServer.CMS.Model.Embeds.AbuseReportCase do
  @moduledoc """
  abuse report user
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.Model.Embeds

  @optional_fields [:reason, :attr]

  embedded_schema do
    field(:reason, :string)
    field(:attr, :string)
    embeds_one(:user, Embeds.User, on_replace: :delete)

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
    |> cast_embed(:user, required: true, with: &Embeds.User.changeset/2)
  end
end
