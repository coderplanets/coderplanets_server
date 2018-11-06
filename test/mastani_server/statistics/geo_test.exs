defmodule MastaniServer.Test.Statistics.Geo do
  use MastaniServer.TestTools

  alias Helper.{ORM, GeoPool}
  alias MastaniServer.{Statistics}

  setup do
    GeoPool.insert_geo_data()

    # {:ok, ~m(user_conn guest_conn community)a}
  end

  describe "[statistics geo inc] " do
    test "geo data can be inc by city" do
      {:ok, _} = Statistics.UserGeoInfo |> ORM.find_by(%{city: "成都"})

      {:ok, _} = Statistics.inc_count("成都")

      {:ok, updated} = Statistics.UserGeoInfo |> ORM.find_by(%{city: "成都"})
      assert updated.value == 1
      {:ok, _} = Statistics.inc_count("成都")

      {:ok, updated} = Statistics.UserGeoInfo |> ORM.find_by(%{city: "成都"})
      assert updated.value == 2
    end

    test "inc with invalid city fails" do
      assert {:error, _} = Statistics.inc_count("not_exsit")
    end
  end

  describe "[statistics geo get] " do
    test "can get geo citis info" do
      {:ok, infos} = Statistics.list_cities_info()
      assert infos.total_count == 0

      {:ok, _} = Statistics.inc_count("成都")
      {:ok, _} = Statistics.inc_count("成都")
      {:ok, _} = Statistics.inc_count("广州")

      {:ok, infos} = Statistics.list_cities_info()

      assert infos.total_count == 2
      assert infos |> Enum.any?(&(&1.city == "成都"))
      assert infos |> Enum.any?(&(&1.city == "广州"))
    end
  end
end
