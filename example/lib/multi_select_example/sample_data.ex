defmodule MultiSelectExample.SampleData do
  @topics Enum.with_index([
    "Action",
    "History",
    "Fiction",
    "Science Fiction",
    "Documentary",
    "General Literature",
    "Prose",
    "Adventure",
    "Romance",
    "Novel",
    "Poems",
    "Some Long Topic String",
  ], fn(value, i) -> %{id: i+1, value: value} end)

  @topics_map for t <- @topics, into: %{}, do: {t.id, t.value}
  @topics_count length(@topics)

  @sample_data (
    for _ <- 1..100 do
      t1 = :rand.uniform(@topics_count)
      t2 = :rand.uniform(@topics_count)
      t2 = cond do
        t2 != t1 -> t2
        t2 == @topics_count -> @topics_count-1
        true -> t2+1
      end
      topic_ids = [t1, t2]
      %{
        title:     Faker.Cannabis.strain(),
        description:
          case :rand.uniform(3) do
            1 ->   Faker.Lorem.Shakespeare.hamlet()
            2 ->   Faker.Lorem.Shakespeare.as_you_like_it()
            3 ->   Faker.Lorem.Shakespeare.king_richard_iii()
            4 ->   Faker.Lorem.Shakespeare.romeo_and_juliet()
          end,
        topics:    (for i <- topic_ids, do: @topics_map[i]),
        topic_ids: MapSet.new(topic_ids),
        image:     "https://robohash.org/set_set4/#{Faker.Lorem.characters(1..10)}.png"
      }
    end)

  @samle_long_data 1..100
    |> Enum.map(fn _ -> Faker.Fruit.En.fruit() end)
    |> Enum.uniq()
    |> Enum.map(& :lists.duplicate(10, &1))
    |> :lists.append()
    |> Enum.with_index(fn a, i -> %{id: i+1, value: "#{a}-#{i+1}"} end)
    |> Enum.sort()

  def list_topics(),   do: @topics
  def map_topics(),    do: @topics_map
  def topics_count(),  do: @topics_count
  def long_data(),     do: @samle_long_data

  def topic_by_id(id), do: @topics_map[id]

  def sample_data(),   do: @sample_data
  def sample_data_by_topic(ids), do:
    Enum.filter(@sample_data, & Enum.any?(ids, fn i -> MapSet.member?(&1.topic_ids, i) end))
end
