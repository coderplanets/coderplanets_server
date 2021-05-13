defmodule GroupherServer.CMS.Embeds.User do
  @moduledoc """
  only used for embeds_many situation
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:user_id, :integer)
    field(:login, :string)
    field(:nickname, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:login, :nickname, :user_id])
    |> validate_required([:login, :nickname])
  end
end
