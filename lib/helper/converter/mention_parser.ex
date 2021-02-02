defmodule Helper.Converter.MentionParser do
  @moduledoc """
  parse mention(@xx) from given string
  see https://gitgud.io/lambadalambda/pleroma/commit/2ab1d915e3a7db329f09332e8b688e4bd405b748
  """

  # @mention_regex ~r/@[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@?[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*/u
  # see: https://github.com/regexhq/mentions-regex/blob/master/index.js#L21
  # in elixir regex shoud replace \ with \\
  # see http://developerworks.github.io/2015/01/02/elixir-regex/
  @mention_regex ~r/(?:^|[^a-zA-Z0-9_＠!@#$%&*])(?:(?:@|＠)(?!\/))([a-zA-Z0-9\/_.]{1,15})(?:\b(?!@|＠)|$)/

  @doc """
  parse mention(@xx) from given string
  """
  def parse(text, :mentions) do
    Regex.scan(@mention_regex, text)
    |> List.flatten()
    |> Enum.map(&String.trim(&1))
    |> Enum.filter(&String.starts_with?(&1, "@"))
    |> Enum.uniq()
  end
end
