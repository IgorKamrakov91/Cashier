defmodule Cashier.PricingRules.BulkDiscountTest do
  use ExUnit.Case, async: true

  alias Cashier.PricingRules.BulkDiscount

  @opts [product_code: "SR1", threshold: 3, discount_price: "4.50"]

  describe "calculate/3 for strawberries (SR1)" do
    test "one item — full price" do
      items = ["SR1"]
      result = BulkDiscount.calculate(items, "SR1", @opts)

      assert Decimal.equal?(result, Decimal.new("5.00"))
    end

    test "two items — full price" do
      items = ["SR1", "SR1"]
      result = BulkDiscount.calculate(items, "SR1", @opts)

      assert Decimal.equal?(result, Decimal.new("10.00"))
    end

    test "three items — discount kicks in" do
      items = ["SR1", "SR1", "SR1"]
      result = BulkDiscount.calculate(items, "SR1", @opts)

      assert Decimal.equal?(result, Decimal.new("13.50"))
    end

    test "five items — all at discount" do
      items = List.duplicate("SR1", 5)
      result = BulkDiscount.calculate(items, "SR1", @opts)

      assert Decimal.equal?(result, Decimal.new("22.50"))
    end
  end

  describe "calculate/3 for non-target product" do
    test "returns full price for unrelated product" do
      items = ["GR1", "GR1"]
      result = BulkDiscount.calculate(items, "GR1", @opts)

      assert Decimal.equal?(result, Decimal.new("6.22"))
    end
  end
end
