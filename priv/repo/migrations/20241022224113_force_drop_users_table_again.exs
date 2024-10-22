defmodule Pento.Repo.Migrations.ForceDropUsersTableAgain do
  use Ecto.Migration

  def change do
    drop table(:users)
  end
end
