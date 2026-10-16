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

    # SEO
    field :meta_title, :string
    field :meta_description, :string
    field :noindex, :boolean, default: false

    belongs_to :cms_page_template, DeadSimpleCms.Cms.CmsPageTemplate
    belongs_to :og_image, DeadSimpleCms.Cms.CmsImage

    has_many :cms_content_areas, DeadSimpleCms.Cms.CmsContentArea

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:slug, :title, :published, :published_at, :cms_page_template_id, :meta_title, :meta_description, :noindex, :og_image_id])
    |> validate_required([:slug, :title])
    |> update_change(:slug, &DeadSimpleCms.Slug.normalize/1)
    |> validate_length(:slug, min: 1, max: 120)
    |> validate_length(:title, min: 1, max: 200)
    |> validate_length(:meta_title, max: 120)
    |> validate_length(:meta_description, max: 320)
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:og_image_id)
  end
end
