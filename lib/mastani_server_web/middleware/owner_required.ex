# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.OwnerRequired do
  @behaviour Absinthe.Middleware

  import MastaniServer.CMSMisc
  import Helper.Utils

  alias Helper.ORM

  def call(
        %{context: %{cur_user: cur_user}, arguments: %{id: id}, errors: []} = resolution,
        args
      ) do
    with {:ok, part, react} <- parse_args(args),
         {:ok, action} <- match_action(part, react),
         {:ok, content} <- ORM.find(action.reactor, id, preload: action.preload) do
      content_author_id =
        if react == :comment,
          do: content.author.id,
          else: content.author.user_id

      arguments = resolution.arguments |> Map.merge(%{passport_source: content})
      %{resolution | arguments: arguments}
    else
      {:error, err_msg} ->
        resolution
        |> handle_absinthe_error(err_msg)
    end
  end

  def call(resolution, _), do: resolution

  defp parse_args(match: [part, react]), do: {:ok, part, react}
  defp parse_args(match: part), do: {:ok, part, :self}
end
