defmodule Aipos.Repo.Migrations.AddOrganizationToCustomers do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :organization_id, references(:organizations, on_delete: :delete_all)
    end

    create index(:customers, [:organization_id])
  end
end
