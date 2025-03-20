defmodule Aipos.Repo.Migrations.AddMissingFieldsToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :description, :text
      add :created_by_id, references(:users, on_delete: :nilify_all)
    end
  end
end
