defmodule DeadSimpleCms.Repo.Migrations.CreateCmsContentAreas do
  use Ecto.Migration

  def change do
    create table(:cms_content_areas, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :position, :integer, null: false, default: 100
      add :name, :string, null: false
      add :visible, :boolean, default: false, null: false
      add :title, :string
      add :subtitle, :string
      add :body_md, :text
      add :cms_page_id, references(:cms_pages, on_delete: :delete_all, type: :binary_id), null: false
      add :cms_image_id, references(:cms_images, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:cms_content_areas, [:cms_page_id, :position])
    create index(:cms_content_areas, [:cms_image_id])
    create unique_index(:cms_content_areas, [:cms_page_id, :name])
  end
end
