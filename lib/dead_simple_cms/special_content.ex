defmodule DeadSimpleCms.SpecialContent do
  @moduledoc """
  The SpecialContent context.
  """

  import Ecto.Query, warn: false

  alias DeadSimpleCms.SpecialContent.CmsBio
  alias DeadSimpleCms.SpecialContent.CmsTestimonial

  defp repo, do: DeadSimpleCms.repo!()

  @doc """
  Returns the list of cms_bios.

  ## Examples

      iex> list_cms_bios()
      [%CmsBio{}, ...]

  """
  def list_cms_bios do
    repo().all(from(cms_bios in CmsBio, preload: [:cms_image]))
  end

  @doc """
  Gets a single cms_bio.

  Raises `Ecto.NoResultsError` if the Cms bio does not exist.

  ## Examples

      iex> get_cms_bio!(123)
      %CmsBio{}

      iex> get_cms_bio!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_bio!(id), do: repo().get!(CmsBio, id) |> repo().preload(:cms_image)

  @doc """
  Creates a cms_bio.

  ## Examples

      iex> create_cms_bio(%{field: value})
      {:ok, %CmsBio{}}

      iex> create_cms_bio(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_bio(attrs) do
    %CmsBio{}
    |> CmsBio.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_bio.

  ## Examples

      iex> update_cms_bio(cms_bio, %{field: new_value})
      {:ok, %CmsBio{}}

      iex> update_cms_bio(cms_bio, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_bio(%CmsBio{} = cms_bio, attrs) do
    cms_bio
    |> CmsBio.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_bio.

  ## Examples

      iex> delete_cms_bio(cms_bio)
      {:ok, %CmsBio{}}

      iex> delete_cms_bio(cms_bio)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_bio(%CmsBio{} = cms_bio) do
    repo().delete(cms_bio)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_bio changes.

  ## Examples

      iex> change_cms_bio(cms_bio)
      %Ecto.Changeset{data: %CmsBio{}}

  """
  def change_cms_bio(%CmsBio{} = cms_bio, attrs \\ %{}) do
    CmsBio.changeset(cms_bio, attrs)
  end

  @doc """
  Returns the list of cms_testimonials.

  ## Examples

      iex> list_cms_testimonials()
      [%CmsTestimonial{}, ...]

  """
  def list_cms_testimonials do
    repo().all(CmsTestimonial)
  end

  @doc """
  Gets a single cms_testimonial.

  Raises `Ecto.NoResultsError` if the Cms testimonial does not exist.

  ## Examples

      iex> get_cms_testimonial!(123)
      %CmsTestimonial{}

      iex> get_cms_testimonial!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_testimonial!(id), do: repo().get!(CmsTestimonial, id)

  @doc """
  Creates a cms_testimonial.

  ## Examples

      iex> create_cms_testimonial(%{field: value})
      {:ok, %CmsTestimonial{}}

      iex> create_cms_testimonial(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_testimonial(attrs) do
    %CmsTestimonial{}
    |> CmsTestimonial.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_testimonial.

  ## Examples

      iex> update_cms_testimonial(cms_testimonial, %{field: new_value})
      {:ok, %CmsTestimonial{}}

      iex> update_cms_testimonial(cms_testimonial, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_testimonial(%CmsTestimonial{} = cms_testimonial, attrs) do
    cms_testimonial
    |> CmsTestimonial.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_testimonial.

  ## Examples

      iex> delete_cms_testimonial(cms_testimonial)
      {:ok, %CmsTestimonial{}}

      iex> delete_cms_testimonial(cms_testimonial)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_testimonial(%CmsTestimonial{} = cms_testimonial) do
    repo().delete(cms_testimonial)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_testimonial changes.

  ## Examples

      iex> change_cms_testimonial(cms_testimonial)
      %Ecto.Changeset{data: %CmsTestimonial{}}

  """
  def change_cms_testimonial(%CmsTestimonial{} = cms_testimonial, attrs \\ %{}) do
    CmsTestimonial.changeset(cms_testimonial, attrs)
  end
end
