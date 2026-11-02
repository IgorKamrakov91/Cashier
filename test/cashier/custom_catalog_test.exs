defmodule Cashier.CustomCatalogTest do
  # Catalog configuration is application-wide, so these tests must not run asynchronously.
  use ExUnit.Case

  alias Cashier.{Catalog, Product}

  setup do
    previous = Application.fetch_env(:cashier, :catalog_products)

    on_exit(fn ->
      case previous do
        {:ok, products} -> Application.put_env(:cashier, :catalog_products, products)
        :error -> Application.delete_env(:cashier, :catalog_products)
      end
    end)

    :ok
  end

  test "custom products support discounted, full-price, and free items in one checkout" do
    Application.put_env(:cashier, :catalog_products, %{
      "BK1" => Product.new("BK1", "Book", "12.50"),
      "PN1" => Product.new("PN1", "Pen", "1.20"),
      "FREE" => Product.new("FREE", "Bookmark", "0")
    })

    rules = [{Cashier.PricingRules.BuyOneGetOneFree, product_code: "BK1"}]
    assert {:ok, checkout} = Cashier.new(rules)

    try do
      assert :ok = Cashier.scan(checkout, "BK1")
      assert :ok = Cashier.scan(checkout, "BK1")
      assert :ok = Cashier.scan(checkout, "PN1")
      assert :ok = Cashier.scan(checkout, "FREE")
      assert Decimal.equal?(Cashier.total(checkout), Decimal.new("13.70"))

      assert {:error, "unknown product code: \"GR1\""} = Cashier.scan(checkout, "GR1")
      assert Decimal.equal?(Cashier.total(checkout), Decimal.new("13.70"))
    after
      Cashier.stop(checkout)
    end
  end

  test "custom catalog enumeration is sorted by code rather than product name" do
    book = Product.new("BK1", "Zebra book", "12.50")
    pen = Product.new("PN1", "Apple pen", "1.20")
    Application.put_env(:cashier, :catalog_products, %{"PN1" => pen, "BK1" => book})

    assert Catalog.all() == [book, pen]
    assert Catalog.fetch!("BK1") == book
    assert :error = Catalog.fetch("GR1")
  end

  test "an empty custom catalog does not fall back to sample products" do
    Application.put_env(:cashier, :catalog_products, %{})

    assert Catalog.all() == []
    assert :error = Catalog.fetch("GR1")
    assert {:ok, checkout} = Cashier.new()

    try do
      assert {:error, "unknown product code: \"GR1\""} = Cashier.scan(checkout, "GR1")
      assert Decimal.equal?(Cashier.total(checkout), Decimal.new(0))
    after
      Cashier.stop(checkout)
    end

    assert_raise ArgumentError, ~r/references unknown product code: "GR1"/, fn ->
      Cashier.new([{Cashier.PricingRules.BuyOneGetOneFree, product_code: "GR1"}])
    end
  end
end
