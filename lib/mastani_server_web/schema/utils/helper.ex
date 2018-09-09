defmodule MastaniServerWeb.Schema.Utils.Helper do
  @moduledoc """
  common fields
  """
  import Helper.Utils, only: [get_config: 2]
  @page_size get_config(:general, :page_size)
  # @default_inner_page_size 5

  # see: https://github.com/absinthe-graphql/absinthe/issues/363
  defmacro pagination_args do
    quote do
      field(:page, :integer, default_value: 1)
      field(:size, :integer, default_value: unquote(@page_size))
    end
  end

  defmacro pagination_fields do
    quote do
      field(:total_count, :integer)
      field(:page_size, :integer)
      field(:total_pages, :integer)
      field(:page_number, :integer)
    end
  end

  defmacro sscial_fields do
    quote do
      field(:qq, :string)
      field(:weibo, :string)
      field(:weichat, :string)
      field(:github, :string)
      field(:zhihu, :string)
      field(:douban, :string)
      field(:twitter, :string)
      field(:facebook, :string)
      field(:dribble, :string)
      field(:instagram, :string)
      field(:pinterest, :string)
      field(:huaban, :string)
    end
  end
end
