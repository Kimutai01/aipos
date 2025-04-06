defmodule Aipos.Repo.Migrations.CreateSaleItems do
  use Ecto.Migration

  def change do
    create table(:sale_items) do
      add :name, :string
      add :quantity, :integer
      add :price, :decimal
      add :subtotal, :decimal
      add :sale_id, references(:sales, on_delete: :nothing)
      add :product_sku_id, references(:product_skus, on_delete: :nothing)
      add :organization_id, references(:organizations, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:sale_items, [:sale_id])
    create index(:sale_items, [:product_sku_id])
    create index(:sale_items, [:organization_id])
  end
end
