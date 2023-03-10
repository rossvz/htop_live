defmodule Htop.Repo do
  use Ecto.Repo,
    otp_app: :htop,
    adapter: Ecto.Adapters.Postgres
end
