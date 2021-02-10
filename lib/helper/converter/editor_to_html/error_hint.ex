defmodule Helper.Converter.EditorToHTML.ErrorHint do
  @moduledoc """

  see https://stackoverflow.com/a/33052969/4050784
  """

  defmacro watch(type, field) do
    quote do
      @doc "give error hint when #{unquote(field)} is invalid type"
      defp parse_block(%{
             "type" => "#{unquote(type)}",
             "data" => %{
               "#{unquote(field)}" => _
             }
           }) do
        invalid_hint("#{unquote(type)}", "#{unquote(field)}")
      end
    end
  end

  defmacro watch(type, field1, field2) do
    quote do
      @doc "give error hint when #{unquote(field1)} or #{unquote(field2)} is invalid type"
      defp parse_block(%{
             "type" => "#{unquote(type)}",
             "data" => %{
               "#{unquote(field1)}" => _,
               "#{unquote(field2)}" => _
             }
           }) do
        invalid_hint("#{unquote(type)}", "#{unquote(field1)} or #{unquote(field2)}")
      end
    end
  end
end
