defmodule Helper.Converter.EditorGuards do
  @moduledoc """
  guards for incoming editor json

  map_get is not support in current version, so we have to pass each arg for guard
  see: https://elixirforum.com/t/discussion-incorporating-erlang-otp-21-map-guards-in-elixir/14816
  """
  @support_header_levels [1, 2, 3]

  defguard is_valid_header(text, level)
           when is_binary(text) and level in @support_header_levels

  @doc "check if eyebowTitle OR footerTitle are valid"
  defguard is_valid_header(text, level, subtitle)
           when is_binary(text) and level in @support_header_levels and is_binary(subtitle)

  defguard is_valid_header(text, level, eyebrow_title, footer_title)
           when is_binary(text) and level in @support_header_levels and is_binary(eyebrow_title) and
                  is_binary(footer_title)

  defguard is_valid_paragraph(text) when is_binary(text)
end
