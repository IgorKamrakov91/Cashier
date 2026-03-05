defmodule Cashier do
  @moduledoc """
  Convenience API that delegates to `Cashier.Checkout`.

      {:ok, co} = Cashier.new(pricing_rules)
      :ok = Cashier.scan(co, "GR1")
      Cashier.total(co)  #=> Decimal.new("3.11")
      :ok = Cashier.stop(co)
  """

  defdelegate new(pricing_rules \\ [], opts \\ []), to: Cashier.Checkout
  defdelegate scan(checkout, product_code), to: Cashier.Checkout
  defdelegate total(checkout), to: Cashier.Checkout
  defdelegate stop(checkout), to: Cashier.Checkout
end
