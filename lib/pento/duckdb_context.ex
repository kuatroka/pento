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
            Duckdbex.close(db)
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  def close_connection(%{db: db, conn: conn}) do
    # First disconnect the connection, then close the database
    Duckdbex.disconnect(conn)
    Duckdbex.disconnect(db)
  end

  def fetch_cik_page(conn, page) do
    offset = (page - 1) * @page_size
    query = "SELECT cik, cik_name, cik_ticker FROM cik_md LIMIT #{@page_size} OFFSET #{offset}"

    with {:ok, result} <- Duckdbex.query(conn, query),
         {:ok, rows} <- Duckdbex.fetch_all(result),
         {:ok, count_result} <- Duckdbex.query(conn, "SELECT count(*) FROM cik_md"),
         {:ok, [[total_count]]} <- Duckdbex.fetch_all(count_result) do

      processed_rows =
        rows
        |> Enum.with_index()
        |> Enum.map(fn {row, index} ->
          [cik, cik_name, cik_ticker] = row
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
