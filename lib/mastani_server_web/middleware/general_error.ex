# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.GeneralError do
  @behaviour Absinthe.Middleware

  def call(%{errors: [List = errors]} = resolution, _) do
    message = [%{message: errors}]
    IO.inspect(errors, label: "GeneralError")
    %{resolution | value: [], errors: message}
  end

  def call(resolution, _), do: resolution
end
