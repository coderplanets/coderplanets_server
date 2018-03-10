# reference: https://tosbourn.com/testing-absinthe-exunit/

defmodule MastaniServer.AbsintheHelpers do
  def query_skeleton(query, query_name) do
    %{
      "operationName" => "#{query_name}",
      "query" => "query #{query_name} #{query}",
      "variables" => "{}"
    }
  end
end
