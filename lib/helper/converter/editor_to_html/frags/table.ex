defmodule Helper.Converter.EditorToHTML.Frags.Table do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  alias Helper.Converter.EditorToHTML.Class
  # alias Helper.Types, as: T

  @class get_in(Class.article(), ["table"])

  def get_row(group_items) do
    tr_content =
      Enum.reduce(group_items, "", fn item, acc ->
        acc <> frag(:td, item)
      end)

    ~s(<tr>#{tr_content}</tr>)
  end

  def frag(:td, item) do
    %{
      "align" => align,
      # "isZebraStripe" => isZebraStripe,
      "text" => text
    } = item

    IO.inspect(Map.has_key?(item, "width"), label: "the width")

    cell_class = @class["cell"]
    align_class = get_align_class(align)

    case Map.has_key?(item, "width") do
      true ->
        style = ~s(width: #{Map.get(item, "width")})
        ~s(<td style="#{style}"><div class="#{cell_class} #{align_class}">#{text}</div></td>)

      false ->
        ~s(<td><div class="#{cell_class} #{align_class}">#{text}</div></td>)
    end
  end

  defp get_align_class("center"), do: @class["align_center"]
  defp get_align_class("right"), do: @class["align_right"]
  defp get_align_class(_), do: @class["align_left"]
end
