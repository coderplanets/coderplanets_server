defmodule GroupherServer.Test.Helper.UtilsTest do
  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Utils

  describe "map keys to string" do
    @tag :wip
    test "atom keys should covert to string keys on nested map" do
      atom_map = %{
        data: %{
          text: "My in-line-code-content is <b>best</b>"
        },
        type: "paragraph"
      }

      string_map = %{
        "data" => %{
          "text" => "My in-line-code-content is <b>best</b>"
        },
        "type" => "paragraph"
      }

      assert Utils.keys_to_strings(atom_map) == string_map
    end
  end

  describe "[deep merge]" do
    test 'one level of maps without conflict' do
      result = Utils.deep_merge(%{a: 1}, %{b: 2})
      assert result == %{a: 1, b: 2}
    end

    test 'two levels of maps without conflict' do
      result = Utils.deep_merge(%{a: %{b: 1}}, %{a: %{c: 3}})
      assert result == %{a: %{b: 1, c: 3}}
    end

    test 'three levels of maps without conflict' do
      result = Utils.deep_merge(%{a: %{b: %{c: 1}}}, %{a: %{b: %{d: 2}}})
      assert result == %{a: %{b: %{c: 1, d: 2}}}
    end

    test 'non-map value in left' do
      result = Utils.deep_merge(%{a: 1}, %{a: %{b: 2}})
      assert result == %{a: %{b: 2}}
    end

    test 'non-map value in right' do
      result = Utils.deep_merge(%{a: %{b: 1}}, %{a: 2})
      assert result == %{a: 2}
    end

    test 'non-map value in both' do
      result = Utils.deep_merge(%{a: 1}, %{a: 2})
      assert result == %{a: 2}
    end
  end
end
