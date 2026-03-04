defmodule Cashier.CatalogTest do
  use ExUnit.Case, async: true

  alias Cashier.Catalog

  doctest Catalog

  test "fetch/1 returns {:ok, product} for known codes" do
    assert {:ok, product} = Catalog.fetch("GR1")
    assert product.code == "GR1"
    assert product.name == "Green tea"
    assert Decimal.equal?(product.price, Decimal.new("3.11"))
  end

  test "fetch/1 returns :error for unknown codes" do
    assert :error = Catalog.fetch("UNKNOWN")
  end

  test "fetch!/1 raises for unknown codes" do
    assert_raise ArgumentError, ~r/unknown product code/, fn ->
      Catalog.fetch!("UNKNOWN")
    end
  end

  test "all/0 returns all three products" do
    products = Catalog.all()

    assert length(products) == 3
    codes = Enum.map(products, & &1.code) |> Enum.sort()
    assert codes == ["CF1", "GR1", "SR1"]
  end

  test "catalog contains correct prices" do
    assert {:ok, sr1} = Catalog.fetch("SR1")
    assert Decimal.equal?(sr1.price, Decimal.new("5.00"))

    assert {:ok, cf1} = Catalog.fetch("CF1")
    assert Decimal.equal?(cf1.price, Decimal.new("11.23"))
  end
end
