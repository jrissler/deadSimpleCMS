defmodule DeadSimpleCms.SpecialContent.CmsTestimonial do
  @moduledoc """
  CmsTestimonials Schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cms_testimonials" do
    field :name, :string
    field :title, :string
    field :company, :string
    field :source, :string
    field :quote, :string
    field :stars, :integer
    field :visible, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cms_testimonial, attrs) do
    cms_testimonial
    |> cast(attrs, [:name, :title, :company, :source, :quote, :stars, :visible])
    |> validate_required([:name, :quote, :stars, :visible])
    |> validate_number(:stars, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
  end
end
