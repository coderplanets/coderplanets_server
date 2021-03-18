defmodule Helper.Converter.EditorToHTML.Frags.Table do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Types, as: T

  @class get_in(Class.article(), ["table"])

  @spec get_row([T.editor_table_cell()]) :: T.html()
  def get_row(group_items) do
    tr_content =
      Enum.reduce(group_items, "", fn item, acc ->
        cell_type = if Map.has_key?(item, "isHeader"), do: :th, else: :td
        acc <> frag(cell_type, item)
      end)

    ~s(<tr>#{tr_content}</tr>)
  end

  @spec frag(:td, T.editor_table_cell()) :: T.html()
  def frag(:td, item) do
    %{
      "align" => align,
      "isStripe" => is_stripe,
      "text" => text
    } = item

    align_class = get_align_class(align)
    scripe_class = if is_stripe, do: @class["td_stripe"], else: ""

    case Map.has_key?(item, "width") do
      true ->
        style = ~s(width: #{Map.get(item, "width")})

        ~s(<td class="#{scripe_class}" style="#{style}"><div class="#{@class["cell"]} #{
          align_class
        }">#{text}</div></td>)

      false ->
        ~s(<td class="#{scripe_class}"><div class="#{@class["cell"]} #{align_class}">#{text}</div></td>)
    end
  end

  @spec frag(:th, T.editor_table_cell()) :: T.html()
  def frag(:th, item) do
    %{"align" => align, "text" => text} = item
    align_class = get_align_class(align)

    ~s(<th class="#{@class["th_header"]}"><div class="#{@class["cell"]} #{align_class}">#{text}</div></th>)
  end

  defp get_align_class("center"), do: @class["align_center"]
  defp get_align_class("right"), do: @class["align_right"]
  defp get_align_class(_), do: @class["align_left"]
end
