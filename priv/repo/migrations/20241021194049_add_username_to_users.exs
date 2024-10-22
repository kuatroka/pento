defmodule Pento.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
    end
  end

  def down do
    alter table(:users) do
      remove :username
    end
  end
end
