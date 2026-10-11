defmodule Cashier.Catalog do
  @moduledoc """
  Product catalog — lookup by product code.

  Uses a built-in product list by default. Override via application config:

      config :cashier, :catalog_products, %{
        "GR1" => Cashier.Product.new("GR1", "Green tea", "3.11"),
        ...
      }
  """

  alias Cashier.Product

  @default_products %{
    "GR1" => Product.new("GR1", "Green tea", "3.11"),
    "SR1" => Product.new("SR1", "Strawberries", "5.00"),
    "CF1" => Product.new("CF1", "Coffee", "11.23")
  }

  @doc """
  Fetches a product by code. Returns `{:ok, product}` or `:error`.

  Raises `ArgumentError` when a configured catalog is not a map of product
  codes to `Cashier.Product` structs with matching codes and finite,
  non-negative Decimal prices.

  ## Examples

      iex> {:ok, product} = Cashier.Catalog.fetch("GR1")
      iex> product.name
      "Green tea"

      iex> Cashier.Catalog.fetch("INVALID")
      :error

  """
  @spec fetch(String.t()) :: {:ok, Product.t()} | :error
  def fetch(code) do
    Map.fetch(products(), code)
  end

  @doc """
  Like `fetch/1` but raises on missing codes.

  ## Examples

      iex> product = Cashier.Catalog.fetch!("SR1")
      iex> product.name
      "Strawberries"

  """
  @spec fetch!(String.t()) :: Product.t()
  def fetch!(code) do
    case fetch(code) do
      {:ok, product} -> product
      :error -> raise ArgumentError, "unknown product code: #{inspect(code)}"
    end
  end

  @doc "Returns all products ordered by product code."
  @spec all() :: [Product.t()]
  def all do
    products()
    |> Map.values()
    |> Enum.sort_by(& &1.code)
  end

  defp products do
    products = Application.get_env(:cashier, :catalog_products, @default_products)

    unless is_map(products) and
             Enum.all?(products, fn {code, product} ->
               is_binary(code) and match?(%Product{}, product) and
                 product.code == code and match?(%Decimal{}, product.price) and
                 is_integer(product.price.coef) and Decimal.compare(product.price, 0) != :lt
             end) do
      raise ArgumentError,
            ":catalog_products must map string codes to Cashier.Product structs with matching codes and finite, non-negative Decimal prices"
    end

    products
  end
end
