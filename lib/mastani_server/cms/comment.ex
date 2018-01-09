defmodule MastaniServer.CMS.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.Comment


  schema "cms_comments" do
    field :body, :string

    timestamps()
  end

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
