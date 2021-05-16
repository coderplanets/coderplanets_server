defmodule GroupherServer.Test.Helper.Validator.Schema do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Validator.Schema

  describe "[basic schema]" do
    test "string with options" do
      schema = %{"text" => [:string, required: false]}
      data = %{"no_exsit" => "text"}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:string, required: true]}
      data = %{"no_exsit" => "text"}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "should be: string", value: nil}] == error

      schema = %{"text" => [:string, required: true]}
      data = %{"text" => "text"}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:string, min: 5]}
      data = %{"text" => "text"}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "min size: 5", value: "text"}] == error

      schema = %{"text" => [:string, required: false, min: 5]}
      data = %{"text" => "text"}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "min size: 5", value: "text"}] === error

      schema = %{"text" => [:string, min: 5]}
      data = %{"no_exsit" => "text"}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "should be: string", value: nil}] == error

      schema = %{"text" => [:string, required: true, min: 5]}
      data = %{"no_exsit" => "text"}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "should be: string", value: nil}] == error

      schema = %{"text" => [:string, required: true, min: "5"]}
      data = %{"text" => "text"}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "unknow option: min: 5", value: "text"}] == error

      schema = %{"text" => [:string, starts_with: "https://"]}
      data = %{"text" => "text"}
      assert {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "should starts with: https://", value: "text"}] == error

      schema = %{"text" => [:string, allow_empty: false]}
      data = %{"text" => ""}
      assert {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "empty is not allowed", value: ""}] == error

      # IO.inspect(Schema.cast(schema, data), label: "schema result")
    end

    test "number with options" do
      schema = %{"text" => [:number, required: false]}
      data = %{"no_exsit" => 1}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:number, required: true]}
      data = %{"no_exsit" => 1}
      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "should be: number", value: nil}]

      schema = %{"text" => [:number, required: true]}
      data = %{"text" => 1}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:number, min: 5]}
      data = %{"text" => 4}
      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "min size: 5", value: 4}]

      schema = %{"text" => [:number, required: false, min: 5]}
      data = %{"text" => 4}
      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "min size: 5", value: 4}]

      schema = %{"text" => [:number, min: 5]}
      data = %{"no_exsit" => 4}
      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "should be: number", value: nil}]

      schema = %{"text" => [:number, required: true, min: 5]}
      data = %{"no_exsit" => 1}
      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "should be: number", value: nil}]

      # IO.inspect(Schema.cast(schema, data), label: "schema result")
      # hello world
    end

    test "number with wrong option" do
      schema = %{"text" => [:number, required: true, min: "5"]}
      data = %{"text" => 1}

      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "unknow option: min: 5", value: 1}]

      schema = %{"text" => [:number, required: true, no_exsit_option: "xxx"]}
      data = %{"text" => 1}

      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "unknow option: no_exsit_option: xxx", value: 1}]
    end

    test "number with options edage case" do
      schema = %{"text" => [:number, min: 2]}
      data = %{"text" => "aa"}

      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "should be: number", value: "aa"}]
    end

    test "list with options" do
      schema = %{"text" => [:list, required: false]}
      data = %{"no_exsit" => []}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:list, required: true]}
      data = %{"no_exsit" => []}
      {:error, error} = Schema.cast(schema, data)
      assert error == [%{field: "text", message: "should be: list", value: nil}]

      schema = %{"text" => [:list, required: true]}
      data = %{"text" => []}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:list]}
      data = %{"text" => []}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:list, allow_empty: true]}
      data = %{"text" => []}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:list, type: :map]}
      data = %{"text" => [1, 2, 3]}
      {:error, error} = Schema.cast(schema, data)

      assert [%{field: "text", message: "item should be map", value: [1, 2, 3]}] == error

      schema = %{"text" => [:list, allow_empty: false]}
      data = %{"text" => []}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "empty is not allowed", value: []}] == error

      # IO.inspect(Schema.cast(schema, data), label: "schema result")
    end

    test "boolean with options" do
      schema = %{"text" => [:boolean, required: false]}
      data = %{"no_exsit" => false}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [:boolean, required: true]}
      data = %{"no_exsit" => false}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "should be: boolean", value: nil}] == error

      schema = %{"text" => [:boolean, required: true]}
      data = %{"text" => false}
      assert {:ok, _} = Schema.cast(schema, data)
    end

    test "enum with options" do
      schema = %{"text" => [enum: [1, 2, 3], required: false]}
      data = %{"no_exsit" => false}
      assert {:ok, _} = Schema.cast(schema, data)

      schema = %{"text" => [enum: [1, 2, 3], required: true]}
      data = %{"no_exsit" => false}
      {:error, error} = Schema.cast(schema, data)
      assert [%{field: "text", message: "should be: 1 | 2 | 3"}] == error

      schema = %{"text" => [enum: [1, 2, 3]]}
      data = %{"text" => 1}
      assert {:ok, _} = Schema.cast(schema, data)

      # IO.inspect(Schema.cast(schema, data), label: "schema result")
      # hello world
    end

    test "schema invalid option should got error" do
      schema = %{"text" => [:number, allow_empty: false]}
      data = %{"text" => 1}

      {:error, error} = Schema.cast(schema, data)

      assert [%{field: "text", message: "unknow option: allow_empty: false", value: 1}] == error
    end
  end
end
