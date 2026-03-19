defmodule DeadSimpleCms.Repo.Migrations.CreateCmsBios do
  use Ecto.Migration

  def change do
    create table(:cms_bios, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :job_title, :string
      add :tag_line, :string
      add :description, :text
      add :phone_number, :string
      add :email, :string
      add :facebook, :string
      add :instagram, :string
      add :tik_tok, :string
      add :linked_in, :string
      add :slug, :string, null: false
      add :visible, :boolean, default: true, null: false
      add :cms_image_id, references(:cms_images, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:cms_bios, [:cms_image_id])
    create unique_index(:cms_bios, [:slug])
    create index(:cms_bios, [:visible])
  end
end
