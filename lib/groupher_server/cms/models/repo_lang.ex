defmodule GroupherServer.CMS.Model.RepoLang do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(name color)a

  @type t :: %RepoLang{}
  embedded_schema do
    field(:name, :string)
    field(:color, :string)
  end

  @doc false
  def changeset(%RepoLang{} = repo_lang, attrs) do
    repo_lang
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
