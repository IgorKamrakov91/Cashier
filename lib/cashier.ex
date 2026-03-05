defmodule Cashier do
  @moduledoc """
  A supermarket checkout system with flexible pricing rules.

  Provides a convenience API that delegates to `Cashier.Checkout`.

  ## Example

      pricing_rules = [
        {Cashier.PricingRules.BuyOneGetOneFree, product_code: "GR1"},
        {Cashier.PricingRules.BulkDiscount, product_code: "SR1", threshold: 3, discount_price: "4.50"},
        {Cashier.PricingRules.FractionPrice, product_code: "CF1", threshold: 3, fraction: {2, 3}}
      ]

      {:ok, co} = Cashier.new(pricing_rules)
      :ok = Cashier.scan(co, "GR1")
      :ok = Cashier.scan(co, "GR1")
      Cashier.total(co)
      #=> Decimal.new("3.11")

  """

  defdelegate new(pricing_rules \\ []), to: Cashier.Checkout
  defdelegate scan(checkout, product_code), to: Cashier.Checkout
  defdelegate total(checkout), to: Cashier.Checkout
end
