defmodule GroupherServer.Accounts.Model.SourceContribute do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields ~w(web server mobile we_app h5)a

  @type t :: %SourceContribute{}
  embedded_schema do
    field(:web, :boolean)
    field(:server, :boolean)
    field(:mobile, :boolean)
    field(:we_app, :boolean)
    field(:h5, :boolean)
  end

  @doc false
  def changeset(%SourceContribute{} = source_contribute, attrs) do
    source_contribute
    |> cast(attrs, @optional_fields)
  end
end
