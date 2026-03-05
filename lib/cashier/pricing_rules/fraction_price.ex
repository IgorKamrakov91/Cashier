defmodule Cashier.PricingRules.FractionPrice do
  @moduledoc """
  Fraction-based pricing rule.

  When the quantity of a product reaches a threshold, the price of all items
  drops to a fraction of the original price (e.g., two thirds).

  The total is computed as `quantity * price * fraction` to minimize
  rounding errors — the fraction is applied to the batch total, not per item.

  ## Configuration

  - `:threshold` (required) — minimum quantity to trigger the discount
  - `:fraction` (required) — the fraction to apply as a `{numerator, denominator}`
      tuple (e.g., `{2, 3}`)

  ## Example

      rule = {Cashier.PricingRules.FractionPrice,
              product_code: "CF1", threshold: 3, fraction: {2, 3}}
  """

  @behaviour Cashier.PricingRule

  @impl true
  def calculate(quantity, price, opts) do
    threshold = Keyword.fetch!(opts, :threshold)
    fraction = Keyword.fetch!(opts, :fraction)

    if quantity >= threshold do
      apply_fraction(price, quantity, fraction)
    else
      Decimal.mult(price, quantity)
    end
  end

  defp apply_fraction(price, quantity, {numerator, denominator}) do
    price
    |> Decimal.mult(quantity)
    |> Decimal.mult(numerator)
    |> Decimal.div(denominator)
    |> Decimal.round(2)
  end
end
