defmodule MastaniServer.CMS.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Comment, Post}

  schema "cms_comments" do
    field(:body, :string)
    many_to_many(:post, Post, join_through: "cms_posts_comments", on_delete: :delete_all)

    timestamps()
  end

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
