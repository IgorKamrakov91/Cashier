defmodule Cashier.PricingRules.BuyOneGetOneFree do
  @moduledoc """
  Buy-one-get-one-free pricing rule.

  For every two items of the target product, the customer pays for only one.
  If an odd number is purchased, the last one is charged at full price.

  ## Configuration

  - `:product_code` (required) — the product code this rule applies to

  ## Example

      rule = {Cashier.PricingRules.BuyOneGetOneFree, product_code: "GR1"}
  """

  @behaviour Cashier.PricingRule

  alias Cashier.Catalog

  @impl true
  def calculate(items, product_code, opts) do
    rule_product_code = Keyword.fetch!(opts, :product_code)

    if product_code != rule_product_code do
      default_total(items, product_code)
    else
      quantity = Enum.count(items, &(&1 == product_code))
      payable = div(quantity, 2) + rem(quantity, 2)
      price = Catalog.fetch!(product_code).price

      Decimal.mult(price, payable)
    end
  end

  defp default_total(items, product_code) do
    quantity = Enum.count(items, &(&1 == product_code))
    price = Catalog.fetch!(product_code).price

    Decimal.mult(price, quantity)
  end
end
