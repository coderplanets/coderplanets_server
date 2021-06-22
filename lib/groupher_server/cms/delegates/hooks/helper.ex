defmodule GroupherServer.CMS.Delegate.Hooks.Helper do
  @moduledoc """
  helper functions for hooks
  """

  @doc """
  merge same cited article in different blocks
  e.g:
  [
    %{
      block_linker: ["block-zByQI"],
      [group_key]: 190057,
      ..
    },
    %{
      block_linker: ["block-zByQI", "block-ZgKJs"],
      [group_key]: 190057,
      ..
    },
  ]
  """
  def merge_same_block_linker(contents, group_key) do
    contents
    |> Enum.reduce([], fn content, acc ->
      case Enum.find_index(acc, &(Map.get(&1, group_key) == Map.get(content, group_key))) do
        nil ->
          acc ++ [content]

        index ->
          List.update_at(
            acc,
            index,
            &Map.put(&1, :block_linker, &1.block_linker ++ content.block_linker)
          )
      end
    end)
  end
end
