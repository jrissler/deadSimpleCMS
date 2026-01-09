defmodule DeadSimpleCms.Slug do
  @moduledoc false

  def normalize(nil), do: nil

  def normalize(slug) do
    slug
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/\s+/u, "-")
    |> String.replace(~r/[^a-z0-9\-]/u, "")
    |> String.replace(~r/\-+/u, "-")
    |> String.trim("-")
  end
end
