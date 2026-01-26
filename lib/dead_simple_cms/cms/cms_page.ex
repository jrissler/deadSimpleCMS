defmodule DeadSimpleCms.Cms.CmsPage do
  @moduledoc """
  CmsPage schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cms_pages" do
    field :slug, :string
    field :title, :string
    field :published, :boolean, default: false
    field :published_at, :utc_datetime_usec

    has_many :cms_content_areas, DeadSimpleCms.Cms.CmsContentArea

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:slug, :title, :published, :published_at])
    |> validate_required([:slug, :title])
    |> update_change(:slug, &DeadSimpleCms.Slug.normalize/1)
    |> validate_length(:slug, min: 1, max: 120)
    |> validate_length(:title, min: 1, max: 200)
    |> unique_constraint(:slug)
  end
end
