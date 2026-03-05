defmodule Cashier.CheckoutTest do
  use ExUnit.Case, async: true

  alias Cashier.Checkout

  @pricing_rules [
    {Cashier.PricingRules.BuyOneGetOneFree, product_code: "GR1"},
    {Cashier.PricingRules.BulkDiscount, product_code: "SR1", threshold: 3, discount_price: "4.50"},
    {Cashier.PricingRules.FractionPrice, product_code: "CF1", threshold: 3, fraction: {2, 3}}
  ]

  defp scan_items(checkout, items) do
    Enum.each(items, fn item -> :ok = Checkout.scan(checkout, item) end)
  end

  describe "new/1" do
    test "starts a checkout process" do
      assert {:ok, pid} = Checkout.new(@pricing_rules)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "starts with empty cart — total is zero" do
      {:ok, co} = Checkout.new(@pricing_rules)

      assert Decimal.equal?(Checkout.total(co), Decimal.new(0))
    end
  end

  describe "scan/2" do
    test "accepts valid product codes" do
      {:ok, co} = Checkout.new(@pricing_rules)

      assert :ok = Checkout.scan(co, "GR1")
      assert :ok = Checkout.scan(co, "SR1")
      assert :ok = Checkout.scan(co, "CF1")
    end

    test "returns error for unknown product codes" do
      {:ok, co} = Checkout.new(@pricing_rules)

      assert {:error, _reason} = Checkout.scan(co, "UNKNOWN")
    end
  end

  describe "total/1" do
    test "single item without discount" do
      {:ok, co} = Checkout.new(@pricing_rules)
      :ok = Checkout.scan(co, "SR1")

      assert Decimal.equal?(Checkout.total(co), Decimal.new("5.00"))
    end

    test "multiple different items without discounts triggered" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, ["GR1", "SR1", "CF1"])

      assert Decimal.equal?(Checkout.total(co), Decimal.new("19.34"))
    end
  end

  describe "integration — test baskets from spec" do
    test "basket 1: GR1, SR1, GR1, GR1, CF1 = £22.45" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, ["GR1", "SR1", "GR1", "GR1", "CF1"])

      assert Decimal.equal?(Checkout.total(co), Decimal.new("22.45"))
    end

    test "basket 2: GR1, GR1 = £3.11" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, ["GR1", "GR1"])

      assert Decimal.equal?(Checkout.total(co), Decimal.new("3.11"))
    end

    test "basket 3: SR1, SR1, GR1, SR1 = £16.61" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, ["SR1", "SR1", "GR1", "SR1"])

      assert Decimal.equal?(Checkout.total(co), Decimal.new("16.61"))
    end

    test "basket 4: GR1, CF1, SR1, CF1, CF1 = £30.57" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, ["GR1", "CF1", "SR1", "CF1", "CF1"])

      assert Decimal.equal?(Checkout.total(co), Decimal.new("30.57"))
    end
  end
end
