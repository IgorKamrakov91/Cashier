defmodule Cashier.PricingRules.BulkDiscountTest do
  use ExUnit.Case, async: true

  alias Cashier.PricingRules.BulkDiscount

  @price Decimal.new("5.00")
  @opts [product_code: "SR1", threshold: 3, discount_price: "4.50"]

  describe "calculate/3" do
    test "one item — full price" do
      assert Decimal.equal?(BulkDiscount.calculate(1, @price, @opts), Decimal.new("5.00"))
    end

    test "two items — full price" do
      assert Decimal.equal?(BulkDiscount.calculate(2, @price, @opts), Decimal.new("10.00"))
    end

    test "three items — discount kicks in" do
      assert Decimal.equal?(BulkDiscount.calculate(3, @price, @opts), Decimal.new("13.50"))
    end

    test "five items — all at discount" do
      assert Decimal.equal?(BulkDiscount.calculate(5, @price, @opts), Decimal.new("22.50"))
    end
  end
end
