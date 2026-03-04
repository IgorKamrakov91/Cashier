defmodule Cashier.Catalog do
  @moduledoc """
  Product catalog providing lookup by product code.

  Stores the available products in the supermarket. Currently backed by
  a simple map, but the interface is designed to be swappable for a
  database-backed implementation.
  """

  alias Cashier.Product

  @products %{
    "GR1" => Product.new("GR1", "Green tea", "3.11"),
    "SR1" => Product.new("SR1", "Strawberries", "5.00"),
    "CF1" => Product.new("CF1", "Coffee", "11.23")
  }

  @doc """
  Fetches a product by its code.

  Returns `{:ok, product}` if found, `:error` otherwise.

  ## Examples

      iex> {:ok, product} = Cashier.Catalog.fetch("GR1")
      iex> product.name
      "Green tea"

      iex> Cashier.Catalog.fetch("INVALID")
      :error

  """
  @spec fetch(String.t()) :: {:ok, Product.t()} | :error
  def fetch(code) do
    Map.fetch(@products, code)
  end

  @doc """
  Fetches a product by its code, raising if not found.

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

  @doc """
  Returns all products in the catalog.
  """
  @spec all() :: [Product.t()]
  def all, do: Map.values(@products)
end
