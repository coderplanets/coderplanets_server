defmodule GroupherServer.CMS.Model.PostDocument do
  @moduledoc """
  mainly for full-text search
  """
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias CMS.Model.Post

  @timestamps_opts [type: :utc_datetime_usec]

  @max_body_length get_config(:article, :max_length)
  @min_body_length get_config(:article, :min_length)

  @required_fields ~w(body body_html post_id)a
  @optional_fields []

  @type t :: %PostDocument{}
  schema "post_documents" do
    belongs_to(:post, Post, foreign_key: :post_id)

    field(:body, :string)
    field(:body_html, :string)
    field(:toc, :map)
  end

  @doc false
  def changeset(%PostDocument{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end

  @doc false
  def update_changeset(%PostDocument{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end
end
