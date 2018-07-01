defmodule MastaniServerWeb.Schema.Delivery.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  import Helper.Utils, only: [get_config: 2]

  @page_size get_config(:general, :page_size)

  object :mention do
    field(:id, :id)
    field(:from_user_id, :id)
    field(:to_user_id, :id)
    field(:source_title, :string)
    field(:read, :boolean)
  end

  object :paged_mentions do
    field(:entries, list_of(:mention))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end

  object :status do
    field(:done, :boolean)
  end

  input_object :mentions_filter do
    field(:read, :boolean, default_value: false)

    field(:page, :integer, default_value: 1)
    field(:size, :integer, default_value: @page_size)
  end
end
