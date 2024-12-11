# Memory Counter

Just a study project to get better acquainted with Phoenix Live View.

The idea is to have a board of counters that are updated in real time if modified
by different clients.

This app does not use any database and the counters are stored in memory. And as
such, if the server stops/crashes, the data is lost.

## Start

You can simply execute `make up` or `docker compose up` to start the server inside a docker container.

No need to install elixir and dependencies.

Now you can visit <a href="http://localhost:4000/board">http://localhost:4000/board</a>
to start playing around with the counters.

## Tools

- Elixir and Phoenix
- Phoenix Live View
- Tailwind CSS
- Phoenix Pub Sub

## How

The in memory data is stored in another process, which implements the GenServer
behaviour: **MemoryCounter.Server**.

It then exports some functions to manipulate the data (create, delete etc).

Everytime it changes some data, it broadcasts the whole new data to the subscribed listeners
through Phoenix.PubSub.

Obs: Yes, it broadcasts the whole new data, and not just the modified data. Sorry about that!
I hope you don't create millions of counters nor connects millions of clients.

The Live View implements a handle_info that updates the UI with the new state.

## Develop and Makefile

This repo has a Makefile with some useful commands:

Starts a container with the running app:

```
make up
```

Starts a container and a bash session inside it:

```
make bash
```

You can also call help:

```
make help
```

## Distributed mode

Starts a server in distributed erlang mode:

```
make distributed.server
```

This way you can connect to it with.

```
make distributed.connect
```

Now you can interact with the server from another IEx session.
I did not dive into how to configure this with docker, though. )=
