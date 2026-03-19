defmodule DeadSimpleCms.Repo.Migrations.CreateCmsTestimonials do
  use Ecto.Migration

  def change do
    create table(:cms_testimonials, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :title, :string
      add :company, :string
      add :source, :string
      add :quote, :text, null: false
      add :stars, :integer, null: false
      add :visible, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:cms_testimonials, [:visible])
  end
end
