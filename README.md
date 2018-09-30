# Ogawa

## Why the name?

Japanese for "small river", another name for Stream in this particular situation.

Flexible streams for Elixir.

## Rationale

The idea behind this stream, is to be able to plug in different readers (producers), and writers (consumers).
This can be achieved by using Elixir Protocols in order to limit various inputs/outputs. These abstractions can be used
as extension points.
As an example, Stdin can be consider a Reader, and also, Stdout a writer.
Similar to above, we can have a Socket, File, maybe a List.

The implementation of Ogawa, uses the Elixir Stream behind the scene (well, it's more a custom Stream implementation).

By default, Ogawa will handle JSON using the decoder/encoder implementations.

Ogawa can be extended using various extension points:

- custom decoders/encoders - using `OgawaStream.decode_with/2`, and `OgawaStream.encode_with/2` combinators.
- custom reader/writer - using `OgawaStream.Proto.Reader`, and `OgawaStream.Proto.Writer` protocols.
- as well, implementations are needed for `OgawaStream.Proto.From`, and `OgawaStream.Proto.To` in order to be able to accept custom readers/writers (`apps/ogawa_stream/lib/proto/from/` and `ogawa_stream/lib/proto/to/` can be used in order to see how these are being implemented).

As for throttling, in order to support a simple strategy like time based throttling (i.e. set the frequency of stream elements produced),
this can be achieved by using an underlying Erlang process that delays the item producing.

Another very important thing to mention is that a stream by default is limited on 100 elements.
This can be changed by passing an extra argument to the `OgawaStream.from` combinator, also this supports a special value `:all`, but this needs
to be used cautiously.

## OgawaStream API

### Creating a stream

A stream can be created by using a combination of `OgawaStream.make/0`, `OgawaStream.from/3`, `OgawaStream.to/2`, and `OgawaStream.sync/1`, or `OgawaStream.async/1`.

Example:

```
OgawaStream.make()
|> OgawaStream.from(%OgawaStream.Device.Stdin{})
|> OgawaStream.to(%OgawaStream.Device.Stdout{})
|> OgawaStream.sync()
```

`OgawaStream` can be started using one of the two available functions: `sync`, which is waiting infinitely for a Task to complete, and `async` which returns the running Task imediately.

Whenever you call `from/3`, the 3rd argument is an optional `max_results` flag, which tells how many elements would be fetched by default (the default value, if not specified, is 100). There is a magical value for this flag, `:all`, which tells the stream to fetch elements until the stream gets closed.

### Decoders and Encoders

By default, without providing anything else, `OgawaStream` is reading string lines from a reader, parses those lines as JSON, makes them an internal Map, and passes further within the chain.
You can, however, plug in your own Decoder and Encoder, using `decode_with/2`, `encode_with/2` combinators, and decoder and encoder would be a function that takes the element from the stream as input, and spits out whatever you feel it needs to to next within the chain, or to the writer, in the case of encoder.

Example:

Here is an example where we just pass the stream elements down the chain as it is, without doing anything to them (passing the identity function as both Decoder and Encoder):

```
OgawaStream.make()
|> OgawaStream.from([1, 2, 3])
|> OgawaStream.to([])
|> OgawaStream.decode_with(& &1)
|> OgawaStream.encode_with(& &1)
|> OgawaStream.sync()
```

The result of the above execution, should be the identical data that was passed within the reader.

### Readers and Writers

Out of the box, the following Readers and Writers are supported:

- `Stdin` (reader)
- `Stdout` (writer)
- `File` (both)
- `Socket` (both)
- `List` (both)

If, for instance, a HTTP Reader is needed, this can be done by implementing the `OgawaStream.Proto.Reader` protocol for a particular struct (let's say you'll have a struct `Extension.Device.Http`; then you can just pass an `Http` struct to the `from/3` combinator). As an example on how these are implemented, you can check the `apps/ogawa_stream/lib/reader/proto/` folder. For the writers, these can be found within `apps/ogawa_stream/lib/writer/proto/`.

Some of the readers/writers are not that straight forward to be created, therefore they may have a `create` function.

Example:

```
reader = OgawaStream.Device.Socket.create('127.0.0.1', 5555)
OgawaStream.make()
|> OgawaStream.from(reader)
....
```

```
reader = OgawaStream.Device.File.create("/tmp/file/on/disk/test.json")
OgawaStream.make()
|> OgawaStream.from(reader)
....
```

```
reader = OgawaStream.Device.File.create("/tmp/file/on/disk/test.json")
writer = OgawaStream.Device.File.create("/tmp/file/on/disk/out.json")
OgawaStream.make()
|> OgawaStream.from(reader)
|> OgawaStream.to(writer)
....
```

### Using the OgawaStream

In order to use the Stream, first you need to create it (using one of the available devices - `OgawaStream.Device.File`, `OgawaStream.Device.Stdin`, `OgawaStream.Device.Socket`, or if the purpose is just for testing, you can use `List` safely.
Few combinators are available out of the box:

- `reject_by_val/2` - takes the value that will be removed from the JSON object
- `add_pair/2` - add a new key/value pair to the JSON object
- `remove_key/2` - remove a key/value pair based on the given key (similar to `reject_by_val/2`, only that it considers the key, not the value)
- `prefix_key/3` - adds a prefix to the given key within the current JSON object

Other combinators that can be used which makes it possible to roll your own more complex logic:

- `map/2` - simply changes the current item to whatever you feel it makes sense to your business
- `filter/2` - filters only values that passes the predicate
- `throttle/2` - slows the consumption of elements by a given time - e.g. if using value of `1`, each element will be fetched no sooner than 1 second from the previous element.
- `take/2` - returns only a specific number of elements (if this combinator is called, the `max_results` field gets canceled, and the value from take will take precedence).

`map/2`, and `filter/2` are quite powerful combinators, and complex logic can be achieved when uses together.

`apps/ogawa_stream/test/ogawa/stream/` contains tests for the above combinators, which can make it more clear on how they can be used in more edgy situations.

Examples:

```
OgawaStream.make()
|> OgawaStream.from(["{\"x\":\"y\"}", "{\"x\":\"z\"}"])
|> OgawaStream.to([])
|> OgawaStream.add_pair("a", "b")
|> OgawaStream.sync()

# The result would be:
["{\"x\":\"y\", \"a\":\"b\"}", "{\"x\":\"z\", \"a\":\"b\"}"]

OgawaStream.make()
|> OgawaStream.from(["{\"x\":\"y\"}", "{\"x\":\"z\"}"])
|> OgawaStream.to([])
|> OgawaStream.remove_key("x")
|> OgawaStream.sync()

# The result would be:
[]

OgawaStream.make()
|> OgawaStream.from(["{\"x\":\"y\"}", "{\"x\":\"z\"}"])
|> OgawaStream.to([])
|> OgawaStream.prefix_key("x", "X_")
|> OgawaStream.sync()

# The result would be:
["{\"X_x\":\"y\"}", "{\"X_x\":\"z\"}"]

OgawaStream.make()
|> OgawaStream.from(["{\"x\":\"y\"}", "{\"x\":\"z\"}"])
|> OgawaStream.to([])
|> OgawaStream.reject_by_val("y")
|> OgawaStream.sync()

# The result would be:
["{\"x\":\"z\"}"]
```

## Dev

### Prerequisites

- `make`
- `mix >= 1.7`
- `Erlang/OTP >= 20`

## Test

`mix deps.get && mix test`

## Build

- `make build` - this will compile everything
- `make` - this will compile everything, run tests, and create the `ogawa_cli` in your current folder.
- `make cli` - create the `ogawa_cli` escript within your current folder.

## Run

`iex -S mix` - once within the Elixir Shell, you can use the `OgawaStream` as specified above.

### Run the cli

- `make cli`
- `echo '{"id":498,"lat":48.95547655552362,"lng":2.4584877527784696,"created_at":"2016-12-14 07:00:06"}' | ./ogawa_cli -r 48.9554765555236`

### With Docker

- `make -f Makefile.docker build` - will build a docker image for `ogawa_cli` - without running the tests
- `make -f Makefile.docker run` - will `ogawa_cli` built docker images, just to spit out the help
- `make -f Makefile.docker test` - will build a docker image for everything, including tests, basically this is a way to make sure that the whole project cand be tested, within a different environment than where it was initially developed.
- `docker-compose up --build` - will show how ogawa_stream can be used programatically to connect to a streaming socket, and to augment the objects with extra fields.
