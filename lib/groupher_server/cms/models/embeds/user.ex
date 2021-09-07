defmodule GroupherServer.CMS.Model.Embeds.User do
  @moduledoc """
  only used for embeds_many situation
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:user_id, :integer)
    field(:login, :string)
    field(:avatar, :string)
    field(:nickname, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:login, :nickname, :user_id, :avatar])
    |> validate_required([:login, :nickname])
  end
end
