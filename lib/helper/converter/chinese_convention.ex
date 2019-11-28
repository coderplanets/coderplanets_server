defmodule Helper.Converter.ChineseConvention do
  @moduledoc """
  follow's https://github.com/sparanoid/chinese-copywriting-guidelines
  遵循中文排版指南

  - 自动添加空格
  - 中文状态下输入的的 "" 和 '' 会被自动转换成「」以及 『』

  inspired by wordpress plugin cover-lover:
  https://cn.wordpress.org/plugins/corner-bracket-lover/
  """

  require Pangu

  @doc """
  format chinese stirng follows github: sparanoid/chinese-copywriting-guidelines.

  example: "Sephiroth見他”這等’神情‘“,也是悚然一驚:不知我這Ultimate Destructive Magic是否對付得了?"
      to:  "Sephiroth 見他「這等『神情』」, 也是悚然一驚: 不知我這 Ultimate Destructive Magic 是否對付得了?"
  """
  @spec format(binary) :: binary
  def format(text) do
    text
    |> Pangu.spacing()
    |> cover_brackets
  end

  # covert chinese "" and '' to 「」& 『』
  defp cover_brackets(text) do
    text
    |> String.replace("“", "「")
    |> String.replace("”", "」")
    |> String.replace("‘", "『")
    |> String.replace("’", "』")
  end
end
