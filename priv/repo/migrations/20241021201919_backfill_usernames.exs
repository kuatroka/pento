defmodule Pento.Repo.Migrations.BackfillUsernames do
  use Ecto.Migration

  def up do
    execute "UPDATE users SET username = CASE WHEN email IS NULL THEN '' ELSE substr(email, 1, instr(email, '@') - 1) END;"
  end

  def down do
    # No rollback needed
  end
end
