defmodule DeadSimpleCms.Repo.Migrations.CreateCmsSlots do
  use Ecto.Migration

  def change do
    create table(:cms_slots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false
      add :name, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cms_slots, [:key])

    alter table(:cms_content_areas) do
      add :cms_slot_id, references(:cms_slots, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:cms_content_areas, [:cms_slot_id])
  end
end
