defmodule GroupherServer.CMS.Model.ArticleDocument do
  @moduledoc """
  mainly for full-text search
  """
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]

  @timestamps_opts [type: :utc_datetime_usec]

  @max_body_length get_config(:article, :max_length)
  @min_body_length get_config(:article, :min_length)

  @required_fields ~w(thread title article_id body body_html)a
  @optional_fields []

  @type t :: %ArticleDocument{}
  schema "article_documents" do
    field(:thread, :string)
    field(:title, :string)
    field(:article_id, :id)
    field(:body, :string)
    field(:body_html, :string)
    # TODO: 分词数据

    timestamps()
  end

  @doc false
  def changeset(%ArticleDocument{} = doc, attrs) do
    doc
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end

  @doc false
  def update_changeset(%ArticleDocument{} = doc, attrs) do
    doc
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end
end
