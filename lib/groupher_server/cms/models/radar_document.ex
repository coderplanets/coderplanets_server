defmodule GroupherServer.CMS.Model.RadarDocument do
  @moduledoc """
  mainly for full-text search
  """
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias CMS.Model.Radar

  @timestamps_opts [type: :utc_datetime_usec]

  @max_body_length get_config(:article, :max_length)
  @min_body_length get_config(:article, :min_length)

  @required_fields ~w(body body_html radar_id)a
  @optional_fields []

  @type t :: %RadarDocument{}
  schema "radar_documents" do
    belongs_to(:radar, Radar, foreign_key: :radar_id)

    field(:body, :string)
    field(:body_html, :string)
    field(:toc, :map)
  end

  @doc false
  def changeset(%RadarDocument{} = radar, attrs) do
    radar
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end

  @doc false
  def update_changeset(%RadarDocument{} = radar, attrs) do
    radar
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_length(:body, min: @min_body_length, max: @max_body_length)
  end
end
