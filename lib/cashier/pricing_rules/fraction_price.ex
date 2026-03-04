defmodule Cashier.PricingRules.FractionPrice do
  @moduledoc """
  Fraction-based pricing rule.

  When the quantity of a product reaches a threshold, the price of all items
  drops to a fraction of the original price (e.g., two thirds).

  The total is computed as `quantity * price * fraction` to minimize
  rounding errors — the fraction is applied to the batch total, not per item.

  ## Configuration

  - `:product_code` (required) — the product code this rule applies to
  - `:threshold` (required) — minimum quantity to trigger the discount
  - `:fraction` (required) — the fraction to apply as a string (e.g., `"0.6667"`)
      or as a `{numerator, denominator}` tuple (e.g., `{2, 3}`)

  ## Example

      rule = {Cashier.PricingRules.FractionPrice,
              product_code: "CF1", threshold: 3, fraction: {2, 3}}
  """

  @behaviour Cashier.PricingRule

  alias Cashier.Catalog

  @impl true
  def calculate(items, product_code, opts) do
    rule_product_code = Keyword.fetch!(opts, :product_code)

    if product_code != rule_product_code do
      default_total(items, product_code)
    else
      threshold = Keyword.fetch!(opts, :threshold)
      fraction = Keyword.fetch!(opts, :fraction)

      quantity = Enum.count(items, &(&1 == product_code))
      price = Catalog.fetch!(product_code).price

      if quantity >= threshold do
        apply_fraction(price, quantity, fraction)
      else
        Decimal.mult(price, quantity)
      end
    end
  end

  defp apply_fraction(price, quantity, {numerator, denominator}) do
    price
    |> Decimal.mult(quantity)
    |> Decimal.mult(numerator)
    |> Decimal.div(denominator)
    |> Decimal.round(2)
  end

  defp apply_fraction(price, quantity, fraction) when is_binary(fraction) do
    price
    |> Decimal.mult(quantity)
    |> Decimal.mult(Decimal.new(fraction))
    |> Decimal.round(2)
  end

  defp default_total(items, product_code) do
    quantity = Enum.count(items, &(&1 == product_code))
    price = Catalog.fetch!(product_code).price

    Decimal.mult(price, quantity)
  end
end
