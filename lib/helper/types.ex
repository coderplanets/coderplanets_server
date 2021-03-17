defmodule Helper.Types do
  @moduledoc """
  custom @types
  """

  @typedoc """
  Type GraphQL flavor the error format
  """
  @type gq_error :: {:error, [message: String.t(), code: non_neg_integer()]}

  @typedoc """
  general response conventions
  """
  @type done :: {:ok, map} | {:error, map}

  @type id :: non_neg_integer() | String.t()

  @typedoc """
  general contribute type for wiki and cheatshet
  """
  @type github_contributor2 :: %{
          github_id: String.t(),
          avatar: String.t(),
          html_url: String.t(),
          nickname: String.t(),
          bio: nil | String.t(),
          location: nil | String.t(),
          company: nil | String.t()
        }

  @typedoc """
  editor.js's header tool data format
  """
  @type editor_header :: %{
          required(:text) => String.t(),
          required(:level) => String.t(),
          eyebrowTitle: String.t(),
          footerTitle: String.t()
        }

  @typep editor_quote_mode :: :short | :long
  @typedoc """
  editor.js's quote tool data format
  """
  @type editor_quote :: %{
          required(:text) => String.t(),
          required(:mode) => editor_quote_mode,
          caption: String.t()
        }

  @typedoc """
  valid editor.js's list item indent
  """
  @type editor_list_indent :: 0 | 1 | 2 | 3

  @typedoc """
  valid editor.js's list item label type
  """
  @type editor_list_label_type :: :default | :red | :green | :warn

  @typedoc """
  editor.js's list item for order_list | unorder_list | checklist
  """
  @type editor_list_item :: %{
          required(:hideLabel) => String.t(),
          required(:indent) => editor_list_indent,
          required(:label) => String.t(),
          required(:labelType) => editor_list_label_type,
          required(:text) => String.t(),
          prefixIndex: String.t()
        }

  @typedoc """
  editor.js's Table align type
  """
  @type editor_table_align :: :center | :left | :right

  @typedoc """
  editor.js's Table td type
  """
  @type editor_table_cell :: %{
          required(:text) => String.t(),
          required(:align) => editor_table_align,
          isStripe: Boolean.t(),
          isHeader: Boolean.t()
        }

  # @typep editor_image_mode :: :single | :jiugongge | :gallery

  @typedoc """
  editor.js's image item
  """
  @type editor_image_item :: %{
          required(:src) => String.t(),
          caption: String.t(),
          index: Integer.t(),
          width: String.t(),
          height: String.t()
        }

  @typedoc """
  editor.js's people item
  """
  @type editor_people_item :: %{
          required(:id) => String.t(),
          required(:avatar) => String.t(),
          required(:title) => String.t(),
          required(:bio) => String.t(),
          required(:desc) => String.t()
        }

  @typedoc """
  html fragment
  """
  @type html :: String.t()
end
