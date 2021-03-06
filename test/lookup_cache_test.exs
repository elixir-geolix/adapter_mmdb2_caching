defmodule Geolix.Adapter.LookupCacheTest do
  use ExUnit.Case

  defmodule DummyCache do
    alias Geolix.Adapter.LookupCache.CacheAdapter

    @behaviour CacheAdapter

    @impl CacheAdapter
    def cache_workers(_, _), do: []

    @impl CacheAdapter
    def get({1, 1, 1, 1}, _, _, _), do: {:ok, nil}
    def get({2, 2, 2, 2}, _, _, _), do: {:ok, %{:test => :result}}
    def get({3, 3, 3, 3}, _, _, _), do: {:error, :test}

    @impl CacheAdapter
    def load_cache(_, _), do: :ok

    @impl CacheAdapter
    def put(_, _, _, _, _), do: :ok

    @impl CacheAdapter
    def unload_cache(_, _), do: :ok
  end

  test "lookup" do
    database = %{
      id: :lookup_cache,
      adapter: Geolix.Adapter.LookupCache,
      cache: %{
        adapter: DummyCache
      },
      lookup: %{
        adapter: Geolix.Adapter.Fake,
        data: %{{1, 1, 1, 1} => %{test: :result}}
      }
    }

    assert :ok == Geolix.load_database(database)
    assert %{test: :result} == Geolix.lookup({1, 1, 1, 1}, where: database[:id])
  end

  test "lookup from cache" do
    database = %{
      id: :lookup_cache_prefilled,
      adapter: Geolix.Adapter.LookupCache,
      cache: %{
        adapter: DummyCache
      },
      lookup: %{
        adapter: Geolix.Adapter.Fake,
        data: %{}
      }
    }

    assert :ok == Geolix.load_database(database)
    assert %{:test => :result} == Geolix.lookup({2, 2, 2, 2}, where: database[:id])
  end

  test "lookup after cache error" do
    database = %{
      id: :lookup_cache_error,
      adapter: Geolix.Adapter.LookupCache,
      cache: %{
        adapter: DummyCache
      },
      lookup: %{
        adapter: Geolix.Adapter.Fake,
        data: %{{3, 3, 3, 3} => %{test: :error}}
      }
    }

    assert :ok == Geolix.load_database(database)
    assert %{test: :error} == Geolix.lookup({3, 3, 3, 3}, where: database[:id])
  end

  test "metadata" do
    database = %{
      id: :lookup_cache,
      adapter: Geolix.Adapter.LookupCache,
      cache: %{
        adapter: DummyCache
      },
      lookup: %{
        adapter: Geolix.Adapter.Fake,
        data: %{{1, 1, 1, 1} => %{test: :result}}
      }
    }

    assert :ok == Geolix.load_database(database)
    assert %{load_epoch: _} = Geolix.metadata(where: database[:id])
  end

  test "unknown adapter error" do
    database = %{
      id: :error_unknown,
      adapter: Geolix.Adapter.LookupCache,
      cache: %{
        adapter: DummyCache
      },
      lookup: %{
        adapter: UnknownAdapter
      }
    }

    assert {:error, {:config, :unknown_adapter}} == Geolix.load_database(database)
  end

  test "unloading" do
    database = %{
      id: :unloaded_cache,
      adapter: Geolix.Adapter.LookupCache,
      cache: %{
        adapter: DummyCache
      },
      lookup: %{
        adapter: Geolix.Adapter.Fake,
        data: %{{1, 1, 1, 1} => %{test: :result}}
      }
    }

    assert :ok == Geolix.load_database(database)
    refute nil == Geolix.lookup({1, 1, 1, 1}, where: database[:id])
    assert :ok == Geolix.unload_database(database[:id])
    assert nil == Geolix.lookup({1, 1, 1, 1}, where: database[:id])
  end
end
