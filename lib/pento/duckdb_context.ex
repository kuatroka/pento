defmodule Pento.DuckdbContext do
  alias Duckdbex

  @db_path "/Users/yo_macbook/Documents/app_data/TEST_DUCKDB/TEST_DUCKDB_FILE_FULL.duckdb"
  @page_size 10

  def open_connection do
    case Duckdbex.open(@db_path) do
      {:ok, db} ->
        case Duckdbex.connection(db) do
          {:ok, conn} ->
            {:ok, %{db: db, conn: conn}}
          {:error, reason} ->
            db.close()
            {:error, reason}
          other ->
            db.close()
            {:error, "Unexpected return value from Duckdbex.connection/1: #{inspect(other)}"}
        end
      {:error, reason} ->
        {:error, reason}
      other ->
        {:error, "Unexpected return value from Duckdbex.open/1: #{inspect(other)}"}
    end
  end

def close_connection(%{db: db, conn: conn}) do
  # First disconnect the connection, then close the database
  Duckdbex.close(conn)
  Duckdbex.close(db)
end

  def fetch_cik_page(conn, page) do
    offset = (page - 1) * @page_size
    query = "SELECT cik, cik_name, cik_ticker FROM cik_md LIMIT #{@page_size} OFFSET #{offset}"

    with {:ok, result} <- Duckdbex.query(conn, query),
         rows <- Duckdbex.fetch_all(result),
         {:ok, count_result} <- Duckdbex.query(conn, "SELECT count(*) FROM cik_md"),
         [[total_count]] = Duckdbex.fetch_all(count_result) do

      processed_rows =
        rows
        |> Enum.with_index()
        |> Enum.map(fn {[cik, cik_name, cik_ticker], index} ->
          %{
            id: "row-#{cik}",
            cik: cik,
            cik_name: cik_name,
            cik_ticker: cik_ticker || "",
            index: index
          }
        end)

      {:ok, %{
        rows: processed_rows,
        page: page,
        total_pages: ceil(total_count / @page_size),
        total_count: total_count
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
