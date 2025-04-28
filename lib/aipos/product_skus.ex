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
  def list_product_skus(product_id) do
    from(v in ProductSku, where: [product_id: ^product_id], order_by: [asc: :id])
    |> Repo.all()
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

  def get_product_sku!(id) do
    Repo.get!(ProductSku, id)
  end

  def get_product_sku!(product, id), do: Repo.get_by!(ProductSku, product_id: product.id, id: id)

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
    |> get_ai_info()
    |> maybe_delete_cards()
  end

  defp maybe_delete_cards({:ok, product_sku}) do
    card = Aipos.Cards.get_by_card(product_sku.rfid_tag)

    if !is_nil(card) do
      Aipos.Cards.delete_card(card)
    end

    {:ok, product_sku}
  end

  def get_product_sku_by_card(card) do
    from(v in ProductSku, where: [rfid_tag: ^card], limit: 1)
    |> Repo.all()
    |> List.first()
  end

  defp get_ai_info({:ok, product_sku}) do
    case Aipos.Gemini.update_product_with_ai_info(
           product_sku.id,
           product_sku.name,
           product_sku.description,
           product_sku.image
         ) do
      {:ok, updated_product_sku} -> {:ok, updated_product_sku}
      _ -> {:ok, product_sku}
    end
  end

  defp get_ai_info(error), do: error

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

  def update_product_ai_info(product_id, ai_attrs) do
    case get_product(product_id) do
      nil ->
        {:error, :not_found}

      product ->
        product
        |> ProductSku.ai_info_changeset(ai_attrs)
        |> Repo.update()
    end
  end

  def get_product(id), do: Repo.get(ProductSku, id)

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
