defmodule DeadSimpleCms.Repo.Migrations.AddSizeToCmsImages do
  use Ecto.Migration

  def change do
    alter table(:cms_images) do
      add :size, :integer, null: false
    end
  end
end
