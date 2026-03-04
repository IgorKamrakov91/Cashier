defmodule Cashier.PricingRule do
  @moduledoc """
  Behaviour for pricing rules applied during checkout.

  Each pricing rule is a module that knows how to calculate the total
  for a specific product given the items in the cart. Rules are designed
  to be composable and configurable — they can be swapped, added, or
  removed without changing the checkout logic.

  ## Implementing a rule

  A pricing rule is represented as a tuple `{module, opts}` where:
  - `module` implements this behaviour
  - `opts` is a keyword list of configuration passed to `calculate/3`

  ## Example

      defmodule MyRule do
        @behaviour Cashier.PricingRule

        @impl true
        def calculate(items, product_code, _opts) do
          # custom pricing logic
        end
      end

      # Usage: {MyRule, []}
  """

  @doc """
  Calculates the total price for a given product code based on the items in the cart.

  ## Parameters

  - `items` — list of product codes in the cart (e.g., `["GR1", "SR1", "GR1"]`)
  - `product_code` — the product code this rule applies to
  - `opts` — configuration options specific to the rule implementation

  ## Returns

  The total price as a `Decimal` for the given product.
  """
  @callback calculate(
              items :: [String.t()],
              product_code :: String.t(),
              opts :: keyword()
            ) :: Decimal.t()
end
