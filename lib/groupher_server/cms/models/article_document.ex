defmodule GroupherServer.CMS.Model.ArticleDocument do
  @moduledoc """
  mainly for full-text search
  """
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Model.Embeds

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]

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
  def changeset(%ArticleDocument{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  def update_changeset(%ArticleDocument{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
