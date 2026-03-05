defmodule Cashier.Checkout do
  @moduledoc """
  A checkout session modeled as a GenServer process.

  Each checkout holds a list of scanned items and a set of pricing rules.
  Items can be scanned in any order, and the total is computed on demand
  by applying the configured pricing rules.

  ## Usage

      pricing_rules = [
        {Cashier.PricingRules.BuyOneGetOneFree, product_code: "GR1"},
        {Cashier.PricingRules.BulkDiscount, product_code: "SR1", threshold: 3, discount_price: "4.50"},
        {Cashier.PricingRules.FractionPrice, product_code: "CF1", threshold: 3, fraction: {2, 3}}
      ]

      {:ok, co} = Cashier.Checkout.new(pricing_rules)
      :ok = Cashier.Checkout.scan(co, "GR1")
      :ok = Cashier.Checkout.scan(co, "GR1")
      Cashier.Checkout.total(co)
      #=> Decimal.new("3.11")

  """

  use GenServer

  alias Cashier.Catalog

  # --- Client API ---

  @doc """
  Starts a new checkout process with the given pricing rules.

  `pricing_rules` is a list of `{module, opts}` tuples where each module
  implements the `Cashier.PricingRule` behaviour.
  """
  @spec new(list({module(), keyword()})) :: {:ok, pid()}
  def new(pricing_rules \\ []) do
    GenServer.start_link(__MODULE__, %{items: [], pricing_rules: pricing_rules})
  end

  @doc """
  Scans a product by its code, adding it to the cart.

  Returns `:ok` on success, `{:error, reason}` if the product is unknown.
  """
  @spec scan(pid(), String.t()) :: :ok | {:error, String.t()}
  def scan(checkout, product_code) do
    GenServer.call(checkout, {:scan, product_code})
  end

  @doc """
  Computes the total price of all scanned items after applying pricing rules.

  Returns the total as a `Decimal`.
  """
  @spec total(pid()) :: Decimal.t()
  def total(checkout) do
    GenServer.call(checkout, :total)
  end

  # --- Server callbacks ---

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:scan, product_code}, _from, state) do
    case Catalog.fetch(product_code) do
      {:ok, _product} ->
        {:reply, :ok, %{state | items: [product_code | state.items]}}

      :error ->
        {:reply, {:error, "unknown product code: #{product_code}"}, state}
    end
  end

  @impl true
  def handle_call(:total, _from, state) do
    total = calculate_total(state.items, state.pricing_rules)
    {:reply, total, state}
  end

  # --- Private ---

  defp calculate_total(items, pricing_rules) do
    items
    |> Enum.uniq()
    |> Enum.map(fn product_code ->
      calculate_product_total(items, product_code, pricing_rules)
    end)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp calculate_product_total(items, product_code, pricing_rules) do
    case find_rule(product_code, pricing_rules) do
      {module, opts} ->
        module.calculate(items, product_code, opts)

      nil ->
        quantity = Enum.count(items, &(&1 == product_code))
        price = Catalog.fetch!(product_code).price
        Decimal.mult(price, quantity)
    end
  end

  defp find_rule(product_code, pricing_rules) do
    Enum.find(pricing_rules, fn {_module, opts} ->
      Keyword.get(opts, :product_code) == product_code
    end)
  end
end
