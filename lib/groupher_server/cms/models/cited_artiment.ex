defmodule GroupherServer.CMS.Model.CitedArtiment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User

  alias CMS.Model.Comment

  @timestamps_opts [type: :utc_datetime]

  @required_fields ~w(cited_by_type cited_by_id user_id)a
  @article_cast_fields general_article_cast_fields()
  @optional_fields ~w(comment_id block_linker)a ++ @article_cast_fields

  @type t :: %CitedArtiment{}
  schema "cited_artiments" do
    field(:cited_by_type, :string)
    field(:cited_by_id, :id)

    belongs_to(:author, User, foreign_key: :user_id)
    belongs_to(:comment, Comment, foreign_key: :comment_id)

    article_belongs_to_fields()

    field(:block_linker, {:array, :string})
    # content.block_linker = ["block-eee_block-bbb", "block-eee_block-bbb"]
    timestamps()
  end

  @doc false
  def changeset(%CitedArtiment{} = cited_artiment, attrs) do
    cited_artiment
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  def update_changeset(%CitedArtiment{} = cited_artiment, attrs) do
    cited_artiment
    |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
