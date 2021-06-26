defmodule GroupherServer.CMS.Model.GuideDocument do
  @moduledoc """
  mainly for full-text search
  """
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias CMS.Model.Guide

  @timestamps_opts [type: :utc_datetime_usec]

  @max_body_length get_config(:article, :max_length)
  @min_body_length get_config(:article, :min_length)

  @required_fields ~w(body body_html guide_id)a
  @optional_fields []

  @type t :: %GuideDocument{}
  schema "guide_documents" do
    belongs_to(:guide, Guide, foreign_key: :guide_id)

    field(:body, :string)
    field(:body_html, :string)
    field(:toc, :map)
  end

  @doc false
  def changeset(%GuideDocument{} = guide, attrs) do
    guide
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end

  @doc false
  def update_changeset(%GuideDocument{} = guide, attrs) do
    guide
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end
end
