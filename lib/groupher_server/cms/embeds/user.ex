defmodule GroupherServer.CMS.Embeds.User do
  @moduledoc """
  only used for embeds_many situation
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:login, :string)
    field(:nickname, :string)
    # field(:is_article_author, :boolean)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:login, :nickname])
  end
end
