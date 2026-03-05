defmodule Cashier.PricingRules.BulkDiscount do
  @moduledoc """
  Bulk discount: drops unit price when quantity reaches `:threshold`.

  Requires `:threshold` (integer) and `:discount_price` (Decimal).
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
