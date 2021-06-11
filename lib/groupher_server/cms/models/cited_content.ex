defmodule GroupherServer.CMS.Model.CitedContent do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User

  alias CMS.Model.{ArticleComment, Embeds}

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(cited_by_type cited_by_id user_id)a
  @article_cast_fields general_article_fields(:cast)
  @optional_fields ~w(article_comment_id block_linkers)a ++ @article_cast_fields

  @type t :: %CitedContent{}
  schema "cited_contents" do
    field(:cited_by_type, :string)
    field(:cited_by_id, :id)

    belongs_to(:author, User, foreign_key: :user_id)
    belongs_to(:article_comment, ArticleComment, foreign_key: :article_comment_id)

    article_belongs_to_fields()

    field(:block_linkers, {:array, :string})
    # content.block_linker = ["block-eee_block-bbb", "block-eee_block-bbb"]
    timestamps()
  end

  @doc false
  def changeset(%CitedContent{} = cited_content, attrs) do
    cited_content
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  def update_changeset(%CitedContent{} = cited_content, attrs) do
    cited_content
    |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
