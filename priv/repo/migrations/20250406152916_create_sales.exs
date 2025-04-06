defmodule Aipos.Repo.Migrations.CreateSales do
  use Ecto.Migration

  def change do
    create table(:sales) do
      add :total_amount, :decimal
      add :payment_method, :string
      add :amount_tendered, :decimal
      add :change_due, :decimal
      add :status, :string
      add :register_id, references(:registers, on_delete: :nothing)
      add :cashier_id, references(:users, on_delete: :nothing)
      add :customer_id, references(:users, on_delete: :nothing)
      add :organization_id, references(:organizations, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:sales, [:register_id])
    create index(:sales, [:cashier_id])
    create index(:sales, [:customer_id])
    create index(:sales, [:organization_id])
  end
end
