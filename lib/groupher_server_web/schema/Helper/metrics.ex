defmodule GroupherServerWeb.Schema.Helper.Metrics do
  @moduledoc """
  common types might be used in all context
  """
  import GroupherServerWeb.Schema.Helper.Fields

  use Absinthe.Schema.Notation

  object :done do
    field(:done, :boolean)
  end

  object :geo_info do
    field(:city, :string)
    field(:value, :integer)
    field(:long, :float)
    field(:lant, :float)
  end

  object :paged_geo_infos do
    field(:entries, list_of(:geo_info))
    pagination_fields()
  end

  input_object :common_paged_filter do
    pagination_args()
    field(:sort, :inserted_sort_enum, default_value: :desc_inserted)
  end
end
