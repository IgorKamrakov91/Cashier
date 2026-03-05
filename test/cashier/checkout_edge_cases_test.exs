defmodule Cashier.CheckoutEdgeCasesTest do
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

  describe "empty cart" do
    test "total is zero" do
      {:ok, co} = Checkout.new(@pricing_rules)

      assert Decimal.equal?(Checkout.total(co), Decimal.new(0))
    end
  end

  describe "no pricing rules" do
    test "all items charged at full price" do
      {:ok, co} = Checkout.new([])
      scan_items(co, ["GR1", "GR1", "SR1", "CF1"])

      # 2 * 3.11 + 5.00 + 11.23 = 22.45
      assert Decimal.equal?(Checkout.total(co), Decimal.new("22.45"))
    end
  end

  describe "unknown product codes" do
    test "scan rejects unknown code and cart remains unchanged" do
      {:ok, co} = Checkout.new(@pricing_rules)
      :ok = Checkout.scan(co, "GR1")
      assert {:error, _} = Checkout.scan(co, "INVALID")

      # only the green tea should be in the cart
      assert Decimal.equal?(Checkout.total(co), Decimal.new("3.11"))
    end
  end

  describe "scanning order independence" do
    test "same total regardless of scan order — basket 1" do
      items = ["GR1", "SR1", "GR1", "GR1", "CF1"]

      totals =
        items
        |> permutations()
        |> Enum.take(10)
        |> Enum.map(fn perm ->
          {:ok, co} = Checkout.new(@pricing_rules)
          scan_items(co, perm)
          Checkout.total(co)
        end)

      assert Enum.all?(totals, &Decimal.equal?(&1, Decimal.new("22.45")))
    end

    test "same total regardless of scan order — basket 4" do
      items = ["GR1", "CF1", "SR1", "CF1", "CF1"]

      totals =
        items
        |> permutations()
        |> Enum.take(10)
        |> Enum.map(fn perm ->
          {:ok, co} = Checkout.new(@pricing_rules)
          scan_items(co, perm)
          Checkout.total(co)
        end)

      assert Enum.all?(totals, &Decimal.equal?(&1, Decimal.new("30.57")))
    end
  end

  describe "large quantities" do
    test "10 green teas — BOGO pays for 5" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, List.duplicate("GR1", 10))

      # 5 * 3.11 = 15.55
      assert Decimal.equal?(Checkout.total(co), Decimal.new("15.55"))
    end

    test "10 strawberries — all at bulk price" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, List.duplicate("SR1", 10))

      # 10 * 4.50 = 45.00
      assert Decimal.equal?(Checkout.total(co), Decimal.new("45.00"))
    end

    test "10 coffees — all at fraction price" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, List.duplicate("CF1", 10))

      # 10 * 11.23 * 2/3 = 74.87 (rounded)
      assert Decimal.equal?(Checkout.total(co), Decimal.new("74.87"))
    end
  end

  describe "total is idempotent" do
    test "calling total multiple times returns the same result" do
      {:ok, co} = Checkout.new(@pricing_rules)
      scan_items(co, ["GR1", "CF1", "SR1", "CF1", "CF1"])

      total1 = Checkout.total(co)
      total2 = Checkout.total(co)
      total3 = Checkout.total(co)

      assert Decimal.equal?(total1, Decimal.new("30.57"))
      assert Decimal.equal?(total2, Decimal.new("30.57"))
      assert Decimal.equal?(total3, Decimal.new("30.57"))
    end

    test "total updates after scanning more items" do
      {:ok, co} = Checkout.new(@pricing_rules)
      :ok = Checkout.scan(co, "GR1")
      assert Decimal.equal?(Checkout.total(co), Decimal.new("3.11"))

      :ok = Checkout.scan(co, "GR1")
      assert Decimal.equal?(Checkout.total(co), Decimal.new("3.11"))

      :ok = Checkout.scan(co, "GR1")
      assert Decimal.equal?(Checkout.total(co), Decimal.new("6.22"))
    end
  end

  describe "flexible rules — swapping configurations" do
    test "strawberry discount with different threshold" do
      rules = [
        {Cashier.PricingRules.BulkDiscount, product_code: "SR1", threshold: 5, discount_price: "4.00"}
      ]

      {:ok, co} = Checkout.new(rules)
      scan_items(co, List.duplicate("SR1", 4))

      # 4 < 5, no discount
      assert Decimal.equal?(Checkout.total(co), Decimal.new("20.00"))

      {:ok, co2} = Checkout.new(rules)
      scan_items(co2, List.duplicate("SR1", 5))

      # 5 >= 5, discount applies
      assert Decimal.equal?(Checkout.total(co2), Decimal.new("20.00"))
    end

    test "BOGO on coffee instead of green tea" do
      rules = [
        {Cashier.PricingRules.BuyOneGetOneFree, product_code: "CF1"}
      ]

      {:ok, co} = Checkout.new(rules)
      scan_items(co, ["CF1", "CF1"])

      assert Decimal.equal?(Checkout.total(co), Decimal.new("11.23"))
    end
  end

  # Generate permutations (limited, for testing scan order independence)
  defp permutations([]), do: [[]]

  defp permutations(list) do
    for elem <- list, rest <- permutations(list -- [elem]) do
      [elem | rest]
    end
  end
end
