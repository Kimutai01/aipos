defmodule Aipos.Repo.Migrations.AddKraPinToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :kra_pin, :string
    end
  end
end
