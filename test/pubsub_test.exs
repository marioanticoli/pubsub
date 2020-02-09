defmodule PubSubTest do
  use ExUnit.Case

  alias PubSub.{Publisher, Subscriber}

  test "Subscribing to a topic should receive message from that topic." do
    topic = "test_topic"
    message = "This is a test"

    Subscriber.create([topic])
    |> IO.inspect()

    Publisher.publish(topic, message)

    res =
      receive do
        msg -> msg
      after
        1_000 -> "No message received"
      end

    assert res =~ message
  end

  test "When message is published before any subscribers are attached, no messages should be received." do
    topic = "test_topic"
    message = "This is a test"
    timeout_msg = "No message received"

    Publisher.publish(topic, message)

    Subscriber.create([topic])

    res =
      receive do
        msg -> msg
      after
        1_000 -> timeout_msg
      end

    assert res == timeout_msg
  end

  test "Publishing to different topic receives no messages." do
    topic1 = "test_topic1"
    topic2 = "test_topic2"
    message = "This is a test"
    timeout_msg = "No message received"

    Subscriber.create([topic2])
    |> IO.inspect()

    Publisher.publish(topic1, message)

    res =
      receive do
        msg -> msg
      after
        1_000 -> timeout_msg
      end

    assert res == timeout_msg
  end

  test "Two subscribers for a different topic should receive intended messages." do
    topic = "test_topic"
    message = "This is a test"

    client1 = Subscriber.create([topic])
    client2 = Subscriber.create([topic])
    Subscriber.list(topic) |> IO.inspect()

    Publisher.publish(topic, message)

    res2 =
      receive do
        msg -> msg
      after
        1_000 -> "No message received"
      end

    res1 =
      receive do
        msg -> msg
      after
        1_000 -> "No message received"
      end

    assert res2 =~ inspect(client2)
    assert res1 =~ inspect(client1)
  end
end
