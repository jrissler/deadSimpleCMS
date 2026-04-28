defmodule DeadSimpleCms.Cms.CmsContentArea do
  @moduledoc """
  CmsContentArea schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cms_content_areas" do
    field :position, :integer
    field :name, :string
    field :visible, :boolean, default: false
    field :title, :string
    field :subtitle, :string
    field :body_md, :string

    belongs_to :cms_page, DeadSimpleCms.Cms.CmsPage
    belongs_to :cms_page_template, DeadSimpleCms.Cms.CmsPageTemplate
    belongs_to :cms_image, DeadSimpleCms.Cms.CmsImage
    belongs_to :cms_slot, DeadSimpleCms.Cms.CmsSlot

    timestamps(type: :utc_datetime)
  end

  def changeset(area, attrs) do
    area
    |> cast(attrs, [:position, :name, :visible, :title, :subtitle, :body_md, :cms_page_id, :cms_image_id, :cms_slot_id, :cms_page_template_id])
    |> validate_required([:cms_slot_id, :position, :name])
    |> check_constraint(:cms_page_id, name: :page_or_template_required, message: "must belong to either a page or a page template")
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_length(:name, max: 120)
    |> validate_length(:subtitle, max: 200)
    |> validate_length(:body_md, max: 20_000)
    |> unique_constraint(:name, name: :cms_content_areas_cms_page_id_name_index)
    |> foreign_key_constraint(:cms_page_id)
    |> foreign_key_constraint(:cms_image_id)
    |> foreign_key_constraint(:cms_slot_id)
  end
end
