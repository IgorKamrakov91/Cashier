defmodule Cashier.PricingRules.BuyOneGetOneFreeTest do
  use ExUnit.Case, async: true

  alias Cashier.PricingRules.BuyOneGetOneFree

  @opts [product_code: "GR1"]

  describe "calculate/3 for green tea (GR1)" do
    test "single item — no discount" do
      items = ["GR1"]
      result = BuyOneGetOneFree.calculate(items, "GR1", @opts)

      assert Decimal.equal?(result, Decimal.new("3.11"))
    end

    test "two items — pay for one" do
      items = ["GR1", "GR1"]
      result = BuyOneGetOneFree.calculate(items, "GR1", @opts)

      assert Decimal.equal?(result, Decimal.new("3.11"))
    end

    test "three items — pay for two" do
      items = ["GR1", "GR1", "GR1"]
      result = BuyOneGetOneFree.calculate(items, "GR1", @opts)

      assert Decimal.equal?(result, Decimal.new("6.22"))
    end

    test "four items — pay for two" do
      items = ["GR1", "GR1", "GR1", "GR1"]
      result = BuyOneGetOneFree.calculate(items, "GR1", @opts)

      assert Decimal.equal?(result, Decimal.new("6.22"))
    end

    test "five items — pay for three" do
      items = ["GR1", "GR1", "GR1", "GR1", "GR1"]
      result = BuyOneGetOneFree.calculate(items, "GR1", @opts)

      assert Decimal.equal?(result, Decimal.new("9.33"))
    end
  end

  describe "calculate/3 for non-target product" do
    test "returns full price for unrelated product" do
      items = ["SR1", "SR1"]
      result = BuyOneGetOneFree.calculate(items, "SR1", @opts)

      assert Decimal.equal?(result, Decimal.new("10.00"))
    end
  end
end
