defmodule Cashier.PricingRules.FractionPrice do
  @moduledoc """
  Fraction-based discount: all items drop to a fraction of the original
  price once quantity reaches `:threshold`.

  Requires `:threshold` (integer) and `:fraction` as `{numerator, denominator}`.
  The fraction is applied to the batch total to minimise rounding.
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
