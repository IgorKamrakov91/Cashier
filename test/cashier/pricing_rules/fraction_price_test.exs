defmodule Cashier.PricingRules.FractionPriceTest do
  use ExUnit.Case, async: true

  alias Cashier.PricingRules.FractionPrice

  @price Decimal.new("11.23")
  @opts [product_code: "CF1", threshold: 3, fraction: {2, 3}]

  describe "calculate/3 with {numerator, denominator} fraction" do
    test "one item — full price" do
      assert Decimal.equal?(FractionPrice.calculate(1, @price, @opts), Decimal.new("11.23"))
    end

    test "two items — full price" do
      assert Decimal.equal?(FractionPrice.calculate(2, @price, @opts), Decimal.new("22.46"))
    end

    test "three items — fraction applied to batch total" do
      # 3 * 11.23 * 2 / 3 = 22.46
      assert Decimal.equal?(FractionPrice.calculate(3, @price, @opts), Decimal.new("22.46"))
    end

    test "four items — fraction applied" do
      # 4 * 11.23 * 2 / 3 = 29.95 (rounded)
      assert Decimal.equal?(FractionPrice.calculate(4, @price, @opts), Decimal.new("29.95"))
    end
  end
end
