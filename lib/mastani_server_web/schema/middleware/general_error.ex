# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Schema.Middleware.GeneralError do
  @behaviour Absinthe.Middleware

  def call(res, _) do
    # with %{errors: errors} <- res do
    with %{errors: [List = errors]} <- res do
      # IO.inspect errors, label: 'GeneralError2'
      message = [%{message: errors}]
      %{res | value: [], errors: message}
      # res |> Absinthe.Resolution.put_result({:error, msg})
    end
  end
end
