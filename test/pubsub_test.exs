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
        {_pid, msg} -> msg
      after
        1_000 -> "No message received"
      end

    assert res == message
  end

  test "When message is published before any subscribers are attached, no messages should be received." do
    topic = "test_topic"
    message = "This is a test"
    timeout_msg = "No message received"

    Publisher.publish(topic, message)

    Subscriber.create([topic])

    res =
      receive do
        {_pid, msg} -> msg
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
        {_pid, msg} -> msg
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
        r -> r
      after
        1_000 -> "No message received"
      end

    res1 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res1 == {client1, message}
    assert res2 == {client2, message}
  end

  test "Subscribers to wildcard topics should receive all matching messages" do
    assert 1 == 2
  end

  describe "Subscribers with wildcard in the middle of the topic should receive matching messages." do
    test "Single wildcard" do
      assert 1 == 2
    end

    test "Multiple widlcards" do
      assert 1 == 2
    end
  end

  test "Subscribing to wildcard # receives all messages" do
    assert 1 == 2
  end

  test "Subscribing to wild combination of wildcards." do
    assert 1 == 2
  end
end
