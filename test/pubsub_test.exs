defmodule PubSubTest do
  use ExUnit.Case

  alias PubSub.{Publisher, Subscriber}

  test "Subscribing to a topic should receive message from that topic." do
    topic = "/temperature"
    message = "25"

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
    topic = "/temperature"
    message = "25"
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
    timeout_msg = "No message received"

    Subscriber.create(["/other"])
    |> IO.inspect()

    Publisher.publish("/temperature", "25")

    res =
      receive do
        {_pid, msg} -> msg
      after
        1_000 -> timeout_msg
      end

    assert res == timeout_msg
  end

  test "Two subscribers for a different topic should receive intended messages." do
    topic1 = "/temperature"
    message1 = "25"
    topic2 = "/humidity"
    message2 = "125"

    client1 = Subscriber.create([topic1])
    client2 = Subscriber.create([topic2])
    Subscriber.list(topic1) |> IO.inspect()
    Subscriber.list(topic2) |> IO.inspect()

    Publisher.publish(topic1, message1)
    Publisher.publish(topic2, message2)

    res1 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    res2 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res1 == {client1, message1}
    assert res2 == {client2, message2}
  end

  test "Subscribers to wildcard topics should receive all matching messages" do
    subscription = "/home/bedroom/+"
    client1 = Subscriber.create([subscription])
    Subscriber.list(subscription) |> IO.inspect()
    Publisher.publish("/home/bedroom/temperature", "30")
    Publisher.publish("/home/bedroom/humidity", "40")

    res1 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    res2 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res1 == {client1, "30"}
    assert res2 == {client1, "40"}
  end

  describe "Subscribers with wildcard in the middle of the topic should receive matching messages." do
    test "Single wildcard" do
      subscription = "/home/+/temperature"
      client1 = Subscriber.create([subscription])
      Subscriber.list(subscription) |> IO.inspect()

      Publisher.publish("/home/bedroom/temperature", "30")
      Publisher.publish("/home/garage/temperature", "40")
      Publisher.publish("/home/bedroom/humidity", "100")

      res1 =
        receive do
          r -> r
        after
          1_000 -> "No message received"
        end

      res2 =
        receive do
          r -> r
        after
          1_000 -> "No message received"
        end

      res3 =
        receive do
          r -> r
        after
          1_000 -> "No message received"
        end

      assert res1 == {client1, "30"}
      assert res2 == {client1, "40"}
      assert res3 == "No message received"
    end

    test "Multiple widlcards" do
      subscription = "/home/+/temperature/+"
      client1 = Subscriber.create([subscription])
      Subscriber.list(subscription) |> IO.inspect()

      Publisher.publish("/home/bedroom/temperature/celsius", "30")
      Publisher.publish("/home/garage/temperature/fahrenheit", "40")
      Publisher.publish("/home/garage/temperature", "-1")
      Publisher.publish("/home/garage/humidity/rh", "-1")
      Publisher.publish("/office/garage/temperature/celsius", "-1")

      res1 =
        receive do
          r -> r
        after
          1_000 -> "No message received"
        end

      assert res1 == {client1, "30"}

      res2 =
        receive do
          r -> r
        after
          1_000 -> "No message received"
        end

      assert res2 == {client1, "40"}

      res3 =
        receive do
          r -> r
        after
          1_000 -> "No message received"
        end

      assert res3 == "No message received"

      res4 =
        receive do
          r -> r
        after
          1_000 -> "No message received"
        end

      assert res4 == "No message received"

      res5 =
        receive do
          r -> r
        after
          1_000 -> "No message received"
        end

      assert res5 == "No message received"
    end
  end

  test "Subscribing to wildcard # receives all messages" do
    client1 = Subscriber.create(["/home/#"])
    Subscriber.list("/home/#") |> IO.inspect()

    Publisher.publish("/home/bedroom/temperature", "30")
    Publisher.publish("/home/bedroom/humidity", "40")
    Publisher.publish("/office/table/humidity", "50")

    res1 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res1 == {client1, "30"}

    res2 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res2 == {client1, "40"}

    res3 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res3 == "No message received"
  end

  test "Subscribing to wild combination of wildcards." do
    client1 = Subscriber.create(["/group/+/home/+/#"])
    Subscriber.list("/group/+/home/+/#") |> IO.inspect()

    Publisher.publish("/group/1/home/bedroom/humidity", "80")
    Publisher.publish("/group/1/home/bedroom/temperature", "30")
    Publisher.publish("/group/1/home/bedroom/temperature/celsius", "30")
    Publisher.publish("/group/1/home/bedroom/temperature/fahrenheit", "30")
    Publisher.publish("/home/bedroom/humidity", "40")
    Publisher.publish("/office/table/humidity", "50")
    Publisher.publish("/group/1/office/bedroom/humidity", "-1")

    res1 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res1 == {client1, "80"}

    res2 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res2 == {client1, "30"}

    res3 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res3 == {client1, "30"}

    res4 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res4 == {client1, "30"}

    res5 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res5 == "No message received"

    res6 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res6 == "No message received"

    res7 =
      receive do
        r -> r
      after
        1_000 -> "No message received"
      end

    assert res7 == "No message received"
  end
end
