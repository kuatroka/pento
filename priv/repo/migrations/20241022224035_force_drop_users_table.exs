defmodule Pento.Repo.Migrations.ForceDropUsersTable do
  use Ecto.Migration

  def change do
    drop table(:users)
  end
end
