defmodule MultiSelectExampleWeb.SampleData do
  @topics [
    %{id: 1,  label: "Action"},
    %{id: 2,  label: "History"},
    %{id: 3,  label: "Fiction"},
    %{id: 4,  label: "Science Fiction"},
    %{id: 5,  label: "Documentary"},
    %{id: 6,  label: "General Literature"},
    %{id: 7,  label: "Prose"},
    %{id: 8,  label: "Adventure"},
    %{id: 9,  label: "Romance"},
    %{id: 10, label: "Novel"},
    %{id: 11, label: "Poems"},
    %{id: 12, label: "Very Long Topic String1"},
    %{id: 13, label: "Even Longer Topic String That Does Not Fit"},
  ]

  @topics_map for t <- @topics, into: %{}, do: {t.id, t.label}
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
        image:     Faker.Avatar.image_url()
      }
    end)

  def list_topics(),   do: @topics
  def map_topics(),    do: @topics_map
  def topics_count(),  do: @topics_count

  def topic_by_id(id), do: @topics_map[id]

  def sample_data(),   do: @sample_data
  def sample_data_by_topic(ids), do:
    Enum.filter(@sample_data, & Enum.any?(ids, fn i -> MapSet.member?(&1.topic_ids, i) end))
end
