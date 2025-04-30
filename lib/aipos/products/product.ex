defmodule Aipos.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :description, :string
    field :image, :string
    field :name, :string

    belongs_to :organization, Aipos.Organizations.Organization
    belongs_to :user, Aipos.Accounts.User

    has_many :product_skus, Aipos.ProductSkus.ProductSku

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :image, :organization_id, :user_id])
    |> validate_required([:name])
    |> cast_assoc(:product_skus)
  end
end
