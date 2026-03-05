defmodule Cashier.Checkout do
  @moduledoc """
  A checkout session modeled as a supervised GenServer process.

  Each checkout holds a map of scanned items (as a frequency map) and a set
  of pricing rules. Items can be scanned in any order, and the total is
  computed on demand by applying the configured pricing rules.

  Checkouts are started under a `DynamicSupervisor` and automatically
  terminate after an idle timeout (default: 30 minutes).

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
      :ok = Cashier.Checkout.stop(co)

  """

  use GenServer

  alias Cashier.Catalog

  # 30 minutes idle timeout
  @default_timeout :timer.minutes(30)

  defstruct items: %{},
            rules: %{},
            timeout: @default_timeout

  @type t :: %__MODULE__{
          items: %{String.t() => non_neg_integer()},
          rules: %{String.t() => {module(), keyword()}},
          timeout: non_neg_integer()
        }

  # --- Client API ---

  @doc """
  Starts a new supervised checkout process with the given pricing rules.

  `pricing_rules` is a list of `{module, opts}` tuples where each module
  implements the `Cashier.PricingRule` behaviour. Each rule must include
  a `:product_code` option.

  ## Options

  - `:timeout` — idle timeout in milliseconds (default: 30 minutes).
    The checkout process terminates automatically after being idle for
    this duration.

  Raises `ArgumentError` if any rule is missing `:product_code` or if the
  module does not implement `Cashier.PricingRule`.
  """
  @spec new(list({module(), keyword()}), keyword()) :: {:ok, pid()}
  def new(pricing_rules \\ [], opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    rules_map = validate_and_build_rules!(pricing_rules)

    DynamicSupervisor.start_child(
      Cashier.CheckoutSupervisor,
      {__MODULE__, %__MODULE__{rules: rules_map, timeout: timeout}}
    )
  end

  @doc """
  Stops a checkout process gracefully.
  """
  @spec stop(pid()) :: :ok
  def stop(checkout) do
    GenServer.stop(checkout, :normal)
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

  @doc false
  def child_spec(%__MODULE__{} = state) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [state]},
      restart: :temporary
    }
  end

  @doc false
  def start_link(%__MODULE__{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(%__MODULE__{timeout: timeout} = state) do
    {:ok, state, timeout}
  end

  @impl true
  def handle_call({:scan, product_code}, _from, state) do
    case Catalog.fetch(product_code) do
      {:ok, _product} ->
        new_items = Map.update(state.items, product_code, 1, &(&1 + 1))
        {:reply, :ok, %{state | items: new_items}, state.timeout}

      :error ->
        {:reply, {:error, "unknown product code: #{inspect(product_code)}"}, state, state.timeout}
    end
  end

  @impl true
  def handle_call(:total, _from, state) do
    total = calculate_total(state.items, state.rules)
    {:reply, total, state, state.timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  defp validate_and_build_rules!(pricing_rules) do
    Map.new(pricing_rules, fn {module, opts} ->
      validate_rule!(module, opts)
      product_code = Keyword.fetch!(opts, :product_code)
      {product_code, {module, opts}}
    end)
  end

  defp validate_rule!(module, opts) do
    unless Keyword.has_key?(opts, :product_code) do
      raise ArgumentError,
            "pricing rule #{inspect(module)} is missing required :product_code option"
    end

    unless function_exported?(module, :calculate, 3) do
      raise ArgumentError,
            "#{inspect(module)} does not implement the Cashier.PricingRule behaviour " <>
              "(missing calculate/3)"
    end
  end

  defp calculate_total(items, rules) do
    items
    |> Enum.map(fn {product_code, quantity} ->
      price = Catalog.fetch!(product_code).price

      case Map.fetch(rules, product_code) do
        {:ok, {module, opts}} -> module.calculate(quantity, price, opts)
        :error -> Decimal.mult(price, quantity)
      end
    end)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end
end
