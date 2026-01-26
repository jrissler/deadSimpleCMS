defmodule DeadSimpleCms.Repo.Migrations.CreateCmsImages do
  use Ecto.Migration

  def change do
    create table(:cms_images, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string, null: false
      add :url, :text, null: false
      add :alt, :string
      add :caption, :string
      add :width, :integer
      add :height, :integer
      add :content_type, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:cms_images, [:url])
  end
end
