defmodule Aipos.ProductSkus do
  @moduledoc """
  The ProductSkus context.
  """

  import Ecto.Query, warn: false
  alias Aipos.Repo

  alias Aipos.ProductSkus.ProductSku

  @doc """
  Returns the list of product_skus.

  ## Examples

      iex> list_product_skus()
      [%ProductSku{}, ...]

  """
  def list_product_skus do
    Repo.all(ProductSku)
  end

  @doc """
  Gets a single product_sku.

  Raises `Ecto.NoResultsError` if the Product sku does not exist.

  ## Examples

      iex> get_product_sku!(123)
      %ProductSku{}

      iex> get_product_sku!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product_sku!(id), do: Repo.get!(ProductSku, id)

  @doc """
  Creates a product_sku.

  ## Examples

      iex> create_product_sku(%{field: value})
      {:ok, %ProductSku{}}

      iex> create_product_sku(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product_sku(attrs \\ %{}) do
    %ProductSku{}
    |> ProductSku.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product_sku.

  ## Examples

      iex> update_product_sku(product_sku, %{field: new_value})
      {:ok, %ProductSku{}}

      iex> update_product_sku(product_sku, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product_sku(%ProductSku{} = product_sku, attrs) do
    product_sku
    |> ProductSku.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product_sku.

  ## Examples

      iex> delete_product_sku(product_sku)
      {:ok, %ProductSku{}}

      iex> delete_product_sku(product_sku)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product_sku(%ProductSku{} = product_sku) do
    Repo.delete(product_sku)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product_sku changes.

  ## Examples

      iex> change_product_sku(product_sku)
      %Ecto.Changeset{data: %ProductSku{}}

  """
  def change_product_sku(%ProductSku{} = product_sku, attrs \\ %{}) do
    ProductSku.changeset(product_sku, attrs)
  end
end
