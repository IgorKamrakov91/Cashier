defmodule Cashier.ProductTest do
  use ExUnit.Case, async: true

  alias Cashier.Product

  doctest Product

  test "new/3 creates a product with Decimal price from string" do
    product = Product.new("GR1", "Green tea", "3.11")

    assert product.code == "GR1"
    assert product.name == "Green tea"
    assert Decimal.equal?(product.price, Decimal.new("3.11"))
  end

  test "new/3 accepts integer price" do
    product = Product.new("X1", "Test", 5)

    assert Decimal.equal?(product.price, Decimal.new(5))
  end
end
