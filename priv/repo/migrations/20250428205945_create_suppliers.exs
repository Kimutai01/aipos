defmodule Aipos.Repo.Migrations.CreateSuppliers do
  use Ecto.Migration

  def change do
    create table(:suppliers) do
      add :name, :string
      add :contact_name, :string
      add :phone, :string
      add :email, :string
      add :address, :text
      add :tags, {:array, :string}
      add :status, :string
      add :payment_terms, :string
      add :lead_time, :integer
      add :last_order_date, :date
      add :notes, :text
      add :organization_id, references(:organizations, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:suppliers, [:organization_id])
  end
end
