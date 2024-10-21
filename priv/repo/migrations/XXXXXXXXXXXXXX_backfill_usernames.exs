defmodule Pento.Repo.Migrations.BackfillUsernames do
  use Ecto.Migration

  def change do
  end

  def up do
    execute "UPDATE users SET username = CASE WHEN email IS NULL THEN '' ELSE split_part(email, '@', 1) END;"
  end

  def down do
    # No rollback needed as this is a data migration
  end
end
