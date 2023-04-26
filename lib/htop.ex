defmodule Htop do
  @moduledoc """
  Htop keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def random_number do
    Enum.random(1..9999)
  end

  def my_really_long_function_name(arg) do
    case arg do
      i when i < 50 -> IO.inspect("cool")
      _otherwise -> raise("something went wrong")
    end
  end
end
