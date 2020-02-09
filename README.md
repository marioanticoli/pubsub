# Goal

Your goal is to complete the implementation of simple (in-memory, MQTT-like) [_PubSub_](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) system, by **making the provided test cases pass**.

Messages can be **published** to topics. When this happens, all subscribers which are **subscribed** to a matching topic receive published message.

## Example

1. Two subscribers are subscribed to `/example` topic, with their actions set to print the received message to standard output. When `"hello"` is published to `/example` , `"hello"` will be printed on the screen twice, once by each subscriber.

2. One subscriber is subscribed to `/home/+/temperature`. When message is published to `/home/bedroom/temperature` and `/home/kitchen/temperature`, both messages are received by the subscribers.

3. One subscriber is subscribed to `/home/office/#` . When message is published to `/home/office/temperature` and `/home/office/humidity`, both messages are received by the subscribers.

You can read more about MQTT topic structure on [HiveMQ][d29016f5] website.

## Implementation

The provided Stub exposes two methods, `Publish(topic, T message)` and `Subscribe(topic, Action<T> message)` which need to be implemented. Accompanying test suite should be used to verify the implementation correctness. It's not necessary to make 100% test cases pass.

## Topics

### Publishing

Topic is a non-empty string consisting of a `/` separated `levels`, where each level is identified by _non-empty, case-sensitive, alphanumeric string_. Topic must start with a `/` character but may not end with it, and must contain at least one level.

- Examples of valid topics:

  ```
  /home/bedroom/temperature
       ^       ^__________^
       |            |
    separator     level
  ```

- Examples of invalid topics:

  ```
  /
  home//
  /h!
  ```

### Subscribing

Subscribe topic extends publishing topic, and can contain _wildcards:_ `+` and `#`.

- The `+` substitutes single topic level and it can be placed in any part of the topic,
- The `#` substitutes multiple levels and can be only placed at the end of the topic.

### Matching topics

Some examples of valid subscription topics:

```
/home/bedroom/temperature
/home/bedroom/humidity
```

#### Matching wildcards

The `+` wildcard can substitute any single level, but there may exist multiple of such wildcards.

Example:

```
/home/+/temperature
```

Would match:

```
/home/kitchen/temperature
/home/bedroom/temperature
```

But it would not match:

```
/home/kitchen/humidity (invalid last segment)
/office/kitchen/temperature (invalid first segment)
/home/kitchen/temperature/celsius (Invalid number of levels)
```

--------------------------------------------------------------------------------

The `#` wildcard can substitute a multiple levels, but there may be only one such wildcard and it may only appear at the end of the topic.

Example:

```
/home/#
```

Would match:

```
/home/temperature
/home/humidity
/home/bedroom/temperature
```

But it would not match:

```
/office/temperature
```

Again, you can use [HiveMQ][d29016f5] as a reference.

## Notes

- Implement your solution in `Solution/SimplePubSub.cs`
- If C# isn't your thing, feel free to re-implement test cases in language of your choice.
- Wildcard topics are for bonus points, and as such not all test cases have to pass.
- It's only necessary to make test cases pass with your `in-memory` implementation, there are no requirements outside of what is specified.
- You **may** not use existing PubSub solutions or libaries providing the functionality.

[d29016f5]: http://www.hivemq.com/blog/mqtt-essentials-part-5-mqtt-topics-best-practices "HiveMQ"
