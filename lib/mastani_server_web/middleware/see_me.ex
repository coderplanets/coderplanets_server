# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.SeeMe do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function

  def call(res, _) do
    # with %{errors: errors} <- res do
    # IO.inspect(Map.keys(res), label: 'fucking SeeMe?')
    # IO.inspect(res.context.current_user, label: 'fucking value')
    # res.arguments = %{arg_count: :arg_count, cur_user: 'fuck'}

    IO.inspect("return error", label: "see me")
    # res
    %{res | value: [], errors: ["fuck"]}
    # |> Absinthe.Resolution.put_result({:error, "fuck"})
    # %{res | arguments: Map.merge(res.arguments, %{current_user: res.context.current_user})}
  end
end
