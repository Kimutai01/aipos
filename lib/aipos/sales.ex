defmodule Aipos.Sales do
  @moduledoc """
  The Sales context.
  """

  import Ecto.Query, warn: false
  alias Aipos.Repo

  alias Aipos.Sales.Sale

  @doc """
  Returns the list of sales.

  ## Examples

      iex> list_sales()
      [%Sale{}, ...]

  """
  def list_sales do
    Repo.all(Sale)
  end

  # In lib/aipos/sales.ex

  # Get sale by transaction_id
  def get_sale_by_transaction_id(transaction_id) do
    Repo.one(from s in Sale, where: s.transaction_id == ^transaction_id)
  end

  @doc """
  Gets a single sale.

  Raises `Ecto.NoResultsError` if the Sale does not exist.

  ## Examples

      iex> get_sale!(123)
      %Sale{}

      iex> get_sale!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sale!(id), do: Repo.get!(Sale, id)

  @doc """
  Creates a sale.

  ## Examples

      iex> create_sale(%{field: value})
      {:ok, %Sale{}}

      iex> create_sale(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sale(attrs \\ %{}) do
    %Sale{}
    |> Sale.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sale.

  ## Examples

      iex> update_sale(sale, %{field: new_value})
      {:ok, %Sale{}}

      iex> update_sale(sale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sale(%Sale{} = sale, attrs) do
    sale
    |> Sale.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sale.

  ## Examples

      iex> delete_sale(sale)
      {:ok, %Sale{}}

      iex> delete_sale(sale)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sale(%Sale{} = sale) do
    Repo.delete(sale)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sale changes.

  ## Examples

      iex> change_sale(sale)
      %Ecto.Changeset{data: %Sale{}}

  """
  def change_sale(%Sale{} = sale, attrs \\ %{}) do
    Sale.changeset(sale, attrs)
  end

  alias Aipos.Sales.SaleItem

  @doc """
  Returns the list of sale_items.

  ## Examples

      iex> list_sale_items()
      [%SaleItem{}, ...]

  """
  def list_sale_items do
    Repo.all(SaleItem)
  end

  @doc """
  Gets a single sale_item.

  Raises `Ecto.NoResultsError` if the Sale item does not exist.

  ## Examples

      iex> get_sale_item!(123)
      %SaleItem{}

      iex> get_sale_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sale_item!(id), do: Repo.get!(SaleItem, id)

  @doc """
  Creates a sale_item.

  ## Examples

      iex> create_sale_item(%{field: value})
      {:ok, %SaleItem{}}

      iex> create_sale_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sale_item(attrs \\ %{}) do
    %SaleItem{}
    |> SaleItem.changeset(attrs)
    |> Repo.insert()
  end

  def list_sale_items_by_sale_id(sale_id) do
    Repo.all(from i in SaleItem, where: i.sale_id == ^sale_id)
  end

  @doc """
  Updates a sale_item.

  ## Examples

      iex> update_sale_item(sale_item, %{field: new_value})
      {:ok, %SaleItem{}}

      iex> update_sale_item(sale_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sale_item(%SaleItem{} = sale_item, attrs) do
    sale_item
    |> SaleItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sale_item.

  ## Examples

      iex> delete_sale_item(sale_item)
      {:ok, %SaleItem{}}

      iex> delete_sale_item(sale_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sale_item(%SaleItem{} = sale_item) do
    Repo.delete(sale_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sale_item changes.

  ## Examples

      iex> change_sale_item(sale_item)
      %Ecto.Changeset{data: %SaleItem{}}

  """
  def change_sale_item(%SaleItem{} = sale_item, attrs \\ %{}) do
    SaleItem.changeset(sale_item, attrs)
  end
end
