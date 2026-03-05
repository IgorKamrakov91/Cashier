defmodule Cashier.PricingRules.BulkDiscount do
  @moduledoc """
  Bulk discount pricing rule.

  When the quantity of a product reaches a threshold, the price per item
  drops to a configured discount price.

  ## Configuration

  - `:threshold` (required) — minimum quantity to trigger the discount
  - `:discount_price` (required) — the new price per item (as Decimal)

  ## Example

      rule = {Cashier.PricingRules.BulkDiscount,
              product_code: "SR1", threshold: 3, discount_price: Decimal.new("4.50")}
  """

  @behaviour Cashier.PricingRule

  @impl true
  def calculate(quantity, price, opts) do
    threshold = Keyword.fetch!(opts, :threshold)
    discount_price = Keyword.fetch!(opts, :discount_price)

    effective_price = if quantity >= threshold, do: discount_price, else: price

    Decimal.mult(effective_price, quantity)
  end
end
