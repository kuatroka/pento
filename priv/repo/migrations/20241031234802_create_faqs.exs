defmodule Pento.Repo.Migrations.CreateFaqs do
  use Ecto.Migration

  def change do
    create table(:faqs) do
      add :question, :string
      add :answer, :text
      add :vote_count, :integer
      add :user_id, references(:users, on_delete: :nothing, name: :id)

      timestamps(type: :utc_datetime)
    end

    create index(:faqs, [:user_id])
  end
end
