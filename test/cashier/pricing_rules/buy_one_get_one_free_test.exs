defmodule Cashier.PricingRules.BuyOneGetOneFreeTest do
  use ExUnit.Case, async: true

  alias Cashier.PricingRules.BuyOneGetOneFree

  @price Decimal.new("3.11")
  @opts [product_code: "GR1"]

  describe "calculate/3" do
    test "single item — no discount" do
      assert Decimal.equal?(BuyOneGetOneFree.calculate(1, @price, @opts), Decimal.new("3.11"))
    end

    test "two items — pay for one" do
      assert Decimal.equal?(BuyOneGetOneFree.calculate(2, @price, @opts), Decimal.new("3.11"))
    end

    test "three items — pay for two" do
      assert Decimal.equal?(BuyOneGetOneFree.calculate(3, @price, @opts), Decimal.new("6.22"))
    end

    test "four items — pay for two" do
      assert Decimal.equal?(BuyOneGetOneFree.calculate(4, @price, @opts), Decimal.new("6.22"))
    end

    test "five items — pay for three" do
      assert Decimal.equal?(BuyOneGetOneFree.calculate(5, @price, @opts), Decimal.new("9.33"))
    end
  end
end
