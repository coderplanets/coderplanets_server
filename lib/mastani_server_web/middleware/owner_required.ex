# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.OwnerRequired do
  @behaviour Absinthe.Middleware

  # TODO: only
  import MastaniServer.CMSMisc
  import MastaniServer.Utils.Helper

  defp passport_checkin(user, author_id, others) do
    # IO.inspect(others, label: "others")
    # TODO other roles
    user.id == author_id or user.root or user.role in others
  end

  def call(
        %{context: %{current_user: current_user}, arguments: %{id: id}, errors: []} = resolution,
        args
      ) do
    with {:ok, part, react, others} <- parse_args(args),
         {:ok, action} <- match_action(part, react),
         {:ok, content} <- find(action.reactor, id, preload: action.preload) do
      content_author_id =
        if react == :comment,
          do: content.author.id,
          else: content.author.user_id

      case passport_checkin(current_user, content_author_id, others) do
        true ->
          arguments = resolution.arguments |> Map.merge(%{content_tobe_operate: content})
          %{resolution | arguments: arguments}

        _ ->
          resolution
          |> handle_absinthe_error("OPERATION_DENY: owner or community admin/editor required")
      end
    else
      {:error, err_msg} ->
        resolution
        |> handle_absinthe_error(err_msg)
    end
  end

  def call(resolution, _), do: resolution

  defp parse_args(match: [part, react], others: others), do: {:ok, part, react, others}
  defp parse_args(match: [part, react]), do: {:ok, part, react, [:owner]}

  defp parse_args(match: part, others: others), do: {:ok, part, :self, others}
  defp parse_args(match: part), do: {:ok, part, :self, [:owner]}
end
