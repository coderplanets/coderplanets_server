defmodule GroupherServer.CMS.Model.PostDocument do
  @moduledoc """
  mainly for full-text search
  """
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Model.{Embeds, Post}

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(thread title article_id body body_html post_id)a
  @optional_fields []

  @type t :: %PostDocument{}
  schema "post_documents" do
    field(:thread, :string)
    field(:title, :string)
    field(:article_id, :id)
    field(:body, :string)
    field(:body_html, :string)
    field(:toc, :map)

    belongs_to(:post, Post, foreign_key: :post_id)

    timestamps()
  end

  @doc false
  def changeset(%PostDocument{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  def update_changeset(%PostDocument{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
