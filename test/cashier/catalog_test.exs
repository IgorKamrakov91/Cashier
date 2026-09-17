defmodule Cashier.CatalogTest do
  # This module changes process-wide application configuration in one test.
  use ExUnit.Case

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

  test "all/0 returns all products ordered by code" do
    products = Catalog.all()

    assert Enum.map(products, & &1.code) == ["CF1", "GR1", "SR1"]
  end

  test "catalog contains correct prices" do
    assert {:ok, sr1} = Catalog.fetch("SR1")
    assert Decimal.equal?(sr1.price, Decimal.new("5.00"))

    assert {:ok, cf1} = Catalog.fetch("CF1")
    assert Decimal.equal?(cf1.price, Decimal.new("11.23"))
  end

  test "uses products configured in the application environment" do
    products = %{
      "BK1" => Cashier.Product.new("BK1", "Book", "12.50")
    }

    previous_products = Application.get_env(:cashier, :catalog_products)
    Application.put_env(:cashier, :catalog_products, products)

    on_exit(fn ->
      if previous_products do
        Application.put_env(:cashier, :catalog_products, previous_products)
      else
        Application.delete_env(:cashier, :catalog_products)
      end
    end)

    assert {:ok, product} = Catalog.fetch("BK1")
    assert product.name == "Book"
    assert Decimal.equal?(product.price, Decimal.new("12.50"))
    assert :error = Catalog.fetch("GR1")
  end
end
