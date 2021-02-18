defmodule Helper.Validator.Schema.Matchers do
  @moduledoc """
  matchers for basic type, support required option
  """

  defmacro __using__(types) do
    # can not use Enum.each here, see https://elixirforum.com/t/define-multiple-modules-in-macro-only-last-one-gets-created/1654/4
    for type <- types do
      guard_name = if type == :string, do: "is_binary", else: "is_#{to_string(type)}"

      quote do
        defp match(field, nil, [unquote(type), required: false]), do: done(field, nil)

        defp match(field, value, [unquote(type), required: false])
             when unquote(:"#{guard_name}")(value) do
          done(field, value)
        end

        defp match(field, value, [unquote(type)]) when unquote(:"#{guard_name}")(value),
          do: done(field, value)

        defp match(field, value, [unquote(type), required: false]),
          do: error(field, value, unquote(type))

        defp match(field, value, [unquote(type)]), do: error(field, value, unquote(type))
      end
    end
  end
end
