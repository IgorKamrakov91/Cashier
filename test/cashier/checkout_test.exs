defmodule Cashier.CheckoutTest do
  use ExUnit.Case, async: true

  import Cashier.Test.CheckoutHelper

  @pricing_rules [
    {Cashier.PricingRules.BuyOneGetOneFree, product_code: "GR1"},
    {Cashier.PricingRules.BulkDiscount, product_code: "SR1", threshold: 3, discount_price: "4.50"},
    {Cashier.PricingRules.FractionPrice, product_code: "CF1", threshold: 3, fraction: {2, 3}}
  ]

  describe "new/1" do
    test "starts a checkout process" do
      assert {:ok, pid} = Cashier.new(@pricing_rules)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "empty cart has zero total" do
      {:ok, co} = Cashier.new(@pricing_rules)

      assert Decimal.equal?(Cashier.total(co), Decimal.new(0))
    end
  end

  describe "scan/2" do
    test "accepts valid product codes" do
      {:ok, co} = Cashier.new(@pricing_rules)

      assert :ok = Cashier.scan(co, "GR1")
      assert :ok = Cashier.scan(co, "SR1")
      assert :ok = Cashier.scan(co, "CF1")
    end

    test "rejects unknown product codes without affecting cart" do
      {:ok, co} = Cashier.new(@pricing_rules)
      :ok = Cashier.scan(co, "GR1")
      assert {:error, _} = Cashier.scan(co, "INVALID")

      assert Decimal.equal?(Cashier.total(co), Decimal.new("3.11"))
    end
  end

  describe "total/1" do
    test "single item without discount" do
      {:ok, co} = Cashier.new(@pricing_rules)
      :ok = Cashier.scan(co, "SR1")

      assert Decimal.equal?(Cashier.total(co), Decimal.new("5.00"))
    end

    test "multiple items without discounts triggered" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, ["GR1", "SR1", "CF1"])

      assert Decimal.equal?(Cashier.total(co), Decimal.new("19.34"))
    end

    test "is idempotent — multiple calls return the same result" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, ["GR1", "CF1", "SR1", "CF1", "CF1"])

      total1 = Cashier.total(co)
      total2 = Cashier.total(co)

      assert Decimal.equal?(total1, Decimal.new("30.57"))
      assert Decimal.equal?(total2, Decimal.new("30.57"))
    end

    test "updates after scanning more items" do
      {:ok, co} = Cashier.new(@pricing_rules)
      :ok = Cashier.scan(co, "GR1")
      assert Decimal.equal?(Cashier.total(co), Decimal.new("3.11"))

      :ok = Cashier.scan(co, "GR1")
      assert Decimal.equal?(Cashier.total(co), Decimal.new("3.11"))

      :ok = Cashier.scan(co, "GR1")
      assert Decimal.equal?(Cashier.total(co), Decimal.new("6.22"))
    end

    test "no pricing rules — all items at full price" do
      {:ok, co} = Cashier.new([])
      scan_items(co, ["GR1", "GR1", "SR1", "CF1"])

      assert Decimal.equal?(Cashier.total(co), Decimal.new("22.45"))
    end
  end

  describe "spec baskets" do
    test "GR1, SR1, GR1, GR1, CF1 = £22.45" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, ["GR1", "SR1", "GR1", "GR1", "CF1"])

      assert Decimal.equal?(Cashier.total(co), Decimal.new("22.45"))
    end

    test "GR1, GR1 = £3.11" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, ["GR1", "GR1"])

      assert Decimal.equal?(Cashier.total(co), Decimal.new("3.11"))
    end

    test "SR1, SR1, GR1, SR1 = £16.61" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, ["SR1", "SR1", "GR1", "SR1"])

      assert Decimal.equal?(Cashier.total(co), Decimal.new("16.61"))
    end

    test "GR1, CF1, SR1, CF1, CF1 = £30.57" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, ["GR1", "CF1", "SR1", "CF1", "CF1"])

      assert Decimal.equal?(Cashier.total(co), Decimal.new("30.57"))
    end
  end

  describe "scanning order independence" do
    test "same total regardless of scan order" do
      items = ["GR1", "SR1", "GR1", "GR1", "CF1"]

      totals =
        items
        |> permutations()
        |> Enum.take(10)
        |> Enum.map(fn perm ->
          {:ok, co} = Cashier.new(@pricing_rules)
          scan_items(co, perm)
          Cashier.total(co)
        end)

      assert Enum.all?(totals, &Decimal.equal?(&1, Decimal.new("22.45")))
    end
  end

  describe "large quantities" do
    test "10 green teas — BOGO pays for 5" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, List.duplicate("GR1", 10))

      assert Decimal.equal?(Cashier.total(co), Decimal.new("15.55"))
    end

    test "10 strawberries — all at bulk price" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, List.duplicate("SR1", 10))

      assert Decimal.equal?(Cashier.total(co), Decimal.new("45.00"))
    end

    test "10 coffees — all at fraction price" do
      {:ok, co} = Cashier.new(@pricing_rules)
      scan_items(co, List.duplicate("CF1", 10))

      assert Decimal.equal?(Cashier.total(co), Decimal.new("74.87"))
    end
  end

  describe "flexible rules" do
    test "different threshold for bulk discount" do
      rules = [
        {Cashier.PricingRules.BulkDiscount, product_code: "SR1", threshold: 5, discount_price: "4.00"}
      ]

      {:ok, co} = Cashier.new(rules)
      scan_items(co, List.duplicate("SR1", 4))
      assert Decimal.equal?(Cashier.total(co), Decimal.new("20.00"))

      {:ok, co2} = Cashier.new(rules)
      scan_items(co2, List.duplicate("SR1", 5))
      assert Decimal.equal?(Cashier.total(co2), Decimal.new("20.00"))
    end

    test "BOGO applied to a different product" do
      rules = [{Cashier.PricingRules.BuyOneGetOneFree, product_code: "CF1"}]

      {:ok, co} = Cashier.new(rules)
      scan_items(co, ["CF1", "CF1"])

      assert Decimal.equal?(Cashier.total(co), Decimal.new("11.23"))
    end
  end

  defp permutations([]), do: [[]]

  defp permutations(list) do
    for elem <- list, rest <- permutations(list -- [elem]) do
      [elem | rest]
    end
  end
end
