defmodule Aipos.Repo.Migrations.AddOrganizationIdToProductsAndProductSkus do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :organization_id, references(:organizations, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
    end

    alter table(:product_skus) do
      add :organization_id, references(:organizations, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
    end

    create index(:products, [:organization_id])
    create index(:product_skus, [:organization_id])
  end
end
