defmodule Cashier.PricingRules.FractionPriceTest do
  use ExUnit.Case, async: true

  alias Cashier.PricingRules.FractionPrice

  @opts [product_code: "CF1", threshold: 3, fraction: {2, 3}]

  describe "calculate/3 for coffee (CF1) with {2, 3} fraction" do
    test "one item — full price" do
      items = ["CF1"]
      result = FractionPrice.calculate(items, "CF1", @opts)

      assert Decimal.equal?(result, Decimal.new("11.23"))
    end

    test "two items — full price" do
      items = ["CF1", "CF1"]
      result = FractionPrice.calculate(items, "CF1", @opts)

      assert Decimal.equal?(result, Decimal.new("22.46"))
    end

    test "three items — fraction applied to batch total" do
      items = ["CF1", "CF1", "CF1"]
      result = FractionPrice.calculate(items, "CF1", @opts)

      # 3 * 11.23 * 2 / 3 = 22.46
      assert Decimal.equal?(result, Decimal.new("22.46"))
    end

    test "four items — fraction applied" do
      items = List.duplicate("CF1", 4)
      result = FractionPrice.calculate(items, "CF1", @opts)

      # 4 * 11.23 * 2 / 3 = 29.95 (rounded)
      assert Decimal.equal?(result, Decimal.new("29.95"))
    end
  end

  describe "calculate/3 with string fraction" do
    test "accepts string fraction" do
      opts = [product_code: "CF1", threshold: 3, fraction: "0.5"]
      items = List.duplicate("CF1", 3)
      result = FractionPrice.calculate(items, "CF1", opts)

      # 3 * 11.23 * 0.5 = 16.845 -> 16.85 (rounded)
      assert Decimal.equal?(result, Decimal.new("16.85"))
    end
  end

  describe "calculate/3 for non-target product" do
    test "returns full price for unrelated product" do
      items = ["GR1", "GR1"]
      result = FractionPrice.calculate(items, "GR1", @opts)

      assert Decimal.equal?(result, Decimal.new("6.22"))
    end
  end
end
