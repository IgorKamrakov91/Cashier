defmodule Cashier.PricingRules.FractionPriceTest do
  use ExUnit.Case, async: true

  alias Cashier.PricingRules.FractionPrice

  @price Decimal.new("11.23")
  @opts [product_code: "CF1", threshold: 3, fraction: {2, 3}]

  describe "validate_options!/1" do
    test "accepts free, full-price, and fractional pricing" do
      for fraction <- [{0, 1}, {1, 1}, {2, 3}] do
        assert :ok = FractionPrice.validate_options!(threshold: 1, fraction: fraction)
      end
    end

    test "rejects missing, non-integer, and non-positive thresholds" do
      for threshold <- [nil, 0, -1, 1.5, "3"] do
        assert_raise ArgumentError, ~r/:threshold must be a positive integer/, fn ->
          FractionPrice.validate_options!(threshold: threshold, fraction: {2, 3})
        end
      end
    end

    test "rejects malformed fractions and invalid numerator or denominator values" do
      for fraction <- [nil, 0.5, {1}, {1, 2, 3}, {-1, 3}, {1, 0}, {1, -2}, {1.0, 2}, {1, 2.0}] do
        assert_raise ArgumentError, ~r/:fraction must be a/, fn ->
          FractionPrice.validate_options!(threshold: 3, fraction: fraction)
        end
      end
    end
  end

  describe "calculate/3 boundary cases" do
    test "an empty basket costs zero" do
      assert Decimal.equal?(FractionPrice.calculate(0, @price, @opts), Decimal.new(0))
    end

    test "zero numerator makes the batch free only at the threshold" do
      opts = [threshold: 3, fraction: {0, 1}]

      assert Decimal.equal?(FractionPrice.calculate(2, @price, opts), Decimal.new("22.46"))
      assert Decimal.equal?(FractionPrice.calculate(3, @price, opts), Decimal.new(0))
      assert Decimal.equal?(FractionPrice.calculate(4, @price, opts), Decimal.new(0))
    end

    test "a unit fraction preserves the full batch price" do
      opts = [threshold: 3, fraction: {1, 1}]

      assert Decimal.equal?(FractionPrice.calculate(3, @price, opts), Decimal.new("33.69"))
    end

    test "rounds the batch total rather than each discounted item" do
      opts = [threshold: 3, fraction: {1, 2}]

      # Each discounted item is 0.025: rounding each first would incorrectly cost 0.09.
      assert Decimal.equal?(
               FractionPrice.calculate(3, Decimal.new("0.05"), opts),
               Decimal.new("0.08")
             )
    end
  end

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
