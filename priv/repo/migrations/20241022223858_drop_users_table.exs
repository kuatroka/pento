defmodule Pento.Repo.Migrations.DropUsersTable do
  use Ecto.Migration

  def up do
    drop table(:users)
  end

  def down do
    create table(:users) do
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :inserted_at, :naive_datetime, null: false
      add :updated_at, :naive_datetime, null: false
    end
  end
end
