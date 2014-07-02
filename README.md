Nodus
============================================================================================================================

_(WARNING: EXPERIMENTAL)_

Description
------------------------------------------------------------------------------------------------------------------------------

Framework for [parallel](http://en.wikipedia.org/wiki/Parallelization)
[data-flow](http://en.wikipedia.org/wiki/Dataflow) based applications.


It is influenced by, inspired by, and in many cases similar to:

 * [Functional Reactive Programming](http://en.wikipedia.org/wiki/Functional_reactive_programming) (also
   [here](http://www.reactivemanifesto.org/))
 * [Kahn Process Networks](http://en.wikipedia.org/wiki/Kahn_process_networks)
 * [Algorithmic Skeletons](http://en.wikipedia.org/wiki/Algorithmic_skeleton) (see also [here](https://github.com/ParaPhrase/skel))
 * [Iteratee IO](http://okmij.org/ftp/Streams.html)
 * [Railway Oriented Programming](http://www.slideshare.net/ScottWlaschin/railway-oriented-programming)
 * [Erlang](http://www.erlang.org/)
 * And of course the hundreds of other reinventions with names like
   `/(((data|signal|packet)?(stream|flow)|pipe(line)?|(flow|event|signal|reactive)-(processing|programming|architecture|computing|language)/`
   combined with the multitude of parallelization, concurrency, and clustering paradigms, etc. etc...


### In More Detail ##################################


- [x] Guiding philosophies
  - [x] Steady-state
  - [x] Composable
  - [x] Proportionate
  - [ ] Real-time & simulation-time
  - [ ] Resilient (failure modes as first class features, exception/failure paths, bulkheads, circuitbreakers, hibernation, ...)
- [ ] Simple single-stream sequential
  - [ ] URI-like notation
  - [ ] Token state accumulation
- [ ] Single-stream sequential with explicit sink
- [ ] Single-stream parallel
  - [ ] Branches
  - [ ] Forks
  - [ ] Waypoints
  - [ ] Pattern Branching
- [ ] Multi-stream
- [ ] Getting away with duck-typing



#### Guiding Assumptions

This library and associated commandline tools are most appropriate for these types of (overlapping and somewhat
redundant) problems & constraints:

|        |      |
| ------ | ---- |
| __Dataflow-Oriented__ | Problems where the easiest way to look at it is a (possibly branching) pipeline of operations on a stream of data. |
| __Steady-State__ | Where the processing nodes and overall application have upper bounds on their memory requirements in order to safely and reliably handle very long running streams. i.e., bounded online algorithms and [streaming-algorithms](http://en.wikipedia.org/wiki/Streaming_algorithm) |
| __Functional__   | Most of the generator & processing nodes are usually assumed to be side-effect-free and pure (at least given all previous inputs). |
| __Composable__   | Easy to make nodes out of combinations and networks of other nodes |
| __Proportionate__| Very easy and fast to do a simple pipeline (for example some simple functions that mutate an integer from within the console), but easily scales up to more complex production-ready solutions/projects. It strives to maintain the following inequality:  `effort ≤ problem‐complexity`. |

It is additionally tuned for (but doesn't assume) problems with the following properties:


|        |      |
| ------ | ---- |
| __Parallel__          | For example, map-reduce type problems, or wherever strictly sequential simply isn't required.  |
| __Ordered__           | When there is a natural ordering to the tokens. e.g., a time-series, or bytes from most IO streams; |
| __State-Accumulation__| Where the tokens can accumulate state and where processing nodes can look at previous process results relative to that token as they pass through the graph. As opposed to destructive changes to the token at each process or lack of tokens altogether (like simple functions). |
| __Multi-Stream__      | Potentially create secondary streams that are unsynchronized with the original stream; |
| __Coordinated__       | Dataflow type problems where there is a need to synchronize/coordinate multiple orthogonal streams; |
| __Decoupled__         | A way to cache intermediate results (e.g., half way through the pipeline) so that multiple stream processing applications can be simultaneously writing results and other unrelated processes reading a stream of results- sometimes in sync with when they are being written by the decoupled process. (some good examples to come). |
| __Daemonized__        | Where certain stream sources and graphs of processors and sinks should be managed as a single long-lived system process when desired. |
| __Simulations/Reruns__| Persistent caching nodes (nexus decouplers) etc. allow one to easily simulate reruns of past parts of a stream- possibly generating a new version of subsequently persisted results. |
| __Rewinding__         | Processing nodes that require (bounded) rewinding that propagates to other nodes. |


Use [Little's law](http://en.wikipedia.org/wiki/Little%27s_law) for queue bounds

#### _Example_: Single-Stream Sequential

    +---+     +------+     +------+
    | G | --> | f(x) | --> | g(x) | -->
    +---+     +------+     +------+

* No sink specified at the end, so it simply outputs everything to STDOUT
* Generator types, from simplest to most complex:
  1. Scalar? Not very useful; does it make sense to allow it?
  2. Simpler proc/block/lambda than an enumerable? - instantiate via implicit counter generator with an offset which
     uses the simple proc as the next block (so you could have a generator such as `->(x){Math.sin(x/100.0)}`)
  3. Any enumerable or even just an object with an `each` method (will be made lazy if it isn't already)
  4. Simple DSL
  5. State-machine class
  6. Decoupler
  7. Synchronized Decoupler


---

Components
------------------------------------------------------------------------------------------------------------------------------

### Data #############################################

| Thing     | Otherwise Known As |                                                    |
|-----------|--------------------|----------------------------------------------------------|
| Stream    | Flow, Signal                  | Related ordered data representation- bundled into tokens (chunks). A gradually consumed state |
| Token     | Packet, Event, Chunk, Element, Sample | Coherent instance of stream data being mutated and passing through the pipelines (potentially in parallel) - special values of EOF & Exceptionals |

#### Stream

Defined by:
  * The eventual property distribution of its constituent tokens (possibly given as a shorthand name/"token-type"),
    which, because the token's internal state ends up mirroring the operations that have occurred, means it is also a
    way of describing the graph of process nodes that act on tokens within the stream (explicitly or implicitly- don't
    know yet) (usually all or a subset of a nodus application specification);
  * An origination node for that specific stream (not necessarily a standalone origination node like for an app)
  * A unique session identifier (uuid) identifying this run-instance, possibly shared with other streams (or Nexus' /
    Decouplers)
  * Creates the initial instances of tokens, with a monotonic order indexed from the first token of the session. (Hence,
    streams can be theoretically infinite into the future, but always have a finite well-defined past, at least in the
    context of a session).
  * Sometimes a version, which can affect caching, for example, or conflict resolution when a sink is permanently saving
    state from a running stream, etc.
  * No cycles. Cycle-like behavior is handled by creating another stream with a delay (for example).

**`Stream == token type == (the data accumulated in the token are related) & especially (same intervals/timing)`**

#### Token

  * A chunk of data - the ordered atoms of a stream.
  * Has a "type"/name that coincides with the stream
  * Analogous to a rolling stone gathering moss. The token starts out very small, and accumulates more pieces of
    state/data as it moves through the nodes, with it's most recent state being the most relevant for the next node.
  * Has a tree-like internal view of the accumulated state that ends up mirroring the topology of the node network.

#### Session

  * The context within which the runtime system executes the dataflows/streams.


### Nodes ##############################################

A node may be a generator for one or more streams AND/OR a sink for one or more streams, AND/OR an operator on one or
more streams (accepting tokens from one or more upstream nodes and emitting them to one (or more?) downstream nodes.
Generally though most nodes will deal with only a single stream- and most of those will be processor nodes, sandwiched
between a generator at the beginning and a sink at the end.

| Aspect     | Otherwise Known As  |   |
|------------|---------------------|---|
| Generator  | Observable, Source, Origin, Enumerator, Producer, Start | Has one or more output streams that originate there & are not among its incoming streams (although the incoming streams may have participated in its creation). |
| Sink       | Consumer, Iteratee, Fold, Reducer, End | folds over one or more input streams & emits nothing except a final result/stats if the done/EOF token is encountered. Usually in charge of any external side-effects. |
| Processor  | Observable, Filter, Enumeratee, Operator, Function, Convolution-operation, Transformer | Receives a token from a stream and either passes it through or advances its state before outputting the same stream-type. |
| Junction   | Whenever a node has input from more than one signal |

Most nodes are intra-stream nodes...

Parameterization (applying the specified or calculated parameters) only happens once, when the first token is about to
hit the node. Any state change after that needs to be handled manually.

(maybe nodes with no generators applied get default behavior if they are run standalone- integer sequence generator, for
example, or default to stdin, argf, etc...)

#### Intra-Stream Nodes

Operate on data within a single stream


| Type       | Behavior |
|------------|----------|
| Pipe       | Chains intra-stream nodes together to operate on a token sequentially |
| Branch     | Sends same token down multiple parallel branches (w/ or w/o conditions, w/ or w/o automatic remerge (wait) (?), w/ or w/o infered token subselection). Some paths may be skipped/short-circuited due to conditions. |
| Tap        | Observer, splice, tee ... Semantic sugar to specify a non-synchronizing branch off of a point in a stream from the perspective of the branch (as if it were a generator). Can also be dynamic and/or temporary. |
| (Cached)   | Wrap around a node if it has referential transparency (given all previous input). Might not implement for a while |
|            | |
| Process    | (Map, Node, Function, ...) Simple function on latest token data |
|   System   | A specialized Process that interfaces with an external application (via stdin/stdout/stderr for the most part?) |
|   External | Another specialized Process that interfaces with an external application, this time via some other IPC call/response mechanisms |
|   View     | (Select?) Changes what the next node will consider the "active data" for the token. |
|            | |
| Wait       | (Merge, Synchronize) Named synchronization point that also causes a "view" to be the combination of all merged branches.  timeout logic, subselection logic, etc. |
| 

**NOTES:**

* Branch without remerge -> when first branch path finishes (or none are deemed applicable) parent node operation
  continues forward- meaning the other data may or may not be available by the time it reaches a sink.
* (possibly named sync-points / stream entry/exit points as syntactical sugar to break up description of graph)
* Special `Wait` nodes might include logic that allows a "partial" token to go ahead depending on certain system
  conditions etc.

#### Stream-level Nodes (Inter-stream)

* `Application`: Adhoc collection of process networks meant to be run by itself. Usually with a single generator and a
  single final output sink- although that stuff can be inferred potentially. While it's meant to be standalone, other
  nodes should still be allowed to use it when composing more.
* `Generators`: Shorthand for a node with zero input streams and one or more output streams. In a broader semantic
  perspective a generator is a node that creates any new streams regardless of whether it has input streams (maybe we
  should call those `Originators` or something instead?)
  - [ ] **sequences**/counters
    - [ ] deterministic
      - [ ] integer
        - [ ] monotonic
        - [ ] sequence ... (e.g., from <http://oeis.org>)
      - [ ] real
        - [ ] ... (monotonic with offsets, scaling, ...)
      - [ ] ... (e.g., complex?, digits of irrationals like pi, ...)
    - [ ] stochastic (or deterministic with seed in some cases)
      - [ ] rng ... (prng, high quality, ...)
      - [ ] quasi-random ...
      - [ ] distributions ...
  - [ ] **clocks**/timers ... (including simulated timers? e.g., meaningful timing sequence without waiting the actual intervals between tokens...)
  - [ ] **system** (although usually used as normal internal functions for the nodes instead of streams)
    - [ ] state changes (e.g., network connectivity, service status, ...)
    - [ ] ... (e.g., resource utilization, uptime, network load, ...)
  - [ ] **interprocess**
    - [ ] signals
    - [ ] argv
    - [ ] file
      - [ ] simple/read
      - [ ] followed (i.e., `tail -f`-like or even `-F`)
    - [ ] database ... (via query or change-monitoring etc.)
    - [ ] pipe
      - [ ] stdin
      - [ ] named
      - [ ] unix pipe (via file descriptor)
    - [ ] argf (combo stdin and/or file(s))
    - [ ] message queue
    - [ ] semaphore
    - [ ] shared memory
    - [ ] mmap
    - [ ] unix socket
    - [ ] net
      - [ ] socket
      - [ ] secure socket
      - [ ] HTTP
      - [ ] HTTPS
      - [ ] ... (e.g., AMQP, Erlang-node, ...)
* `Projections` (one input stream, one different output stream with timing change & probably data change):
  - **SeqDelay**: (buffer, drop(n), drop-while, fifo-queue) output stream is same as input tokens but delayed by specified number of steps (implied (n - 1)
    delay when a cycle is specified or detected?)
  - **TimeDelay**: introduce a system-time latency
  - **Sink**: (fold, accumulator, aggregate, reduce, inject) special ending node that only outputs a result stream with a single
    token that reports some reduced version of all input tokens. (can be specified with a single operator, e.g., `:+`
    for sum).
    - **Decoupler**: persists records
    - *Future*:
      - first
      - include?
      - any?
      - count
      - ... other enumerable & functional operators that act on the whole population.
  - **Reject**: (filter) Filters out specified tokens
  - **Select**: (grep, search) Selects specified tokens
  - **Reactors**: Nodes that give an impulse when they encounter certain conditions on the input stream: specifically
    for monitoring and reacting to certain conditions like queue lengths etc. (can be thought of as being implemented
    via -->[tap]-->[select])
  - **Mutate**: Timing of new stream is the same as input, but data has been mutated in a way that incompatible with the
    incoming stream
  - *Future*:
    - pattern detection
    - sample/alias (time-based chunking)
    - sketch (in lieu of sort, for example)
    - chunk
    - collect-concat / flat-map
    - cycle
    - each-cons
    - take, take-while, drop, drop-while, skip, skip-while (?)
    - ... other enumerable-like projection functions
    - ... sink-like enumerable functions but "so far"- e.g., 'current-max,' 'current-minmax', ...
  - *DIFFICULT* (or impossible considering infinite streams and steady-state, but with some possible partial-solutions)
    - reverse, sort, sort-by (although that could be some kind of sketch...)

* `Merge` junctions:
  - **Mux**: when token arrives on any input stream an output token is generated with copies of the latest of all input
    tokens along with how long it has been since those tokens (respectively) arrived.
  - **Zip**: combines specified number of input tokens (at least one each) laterally and emits an output token. Note
    that this can cause non-steady-state behavior (including even race conditions) if one of the streams bottlenecks and
    the other stream builds up a huge backlog. (Need to at least throw an error when this seems like it's happening, and
    ideally even have mechanisms for automatically dropping, etc.)
  - *Future*
    - concat (if it's ever actually needed- nodus isn't really meant for it...)

* `Scatter` junctions:
  - **Switch**: output streams contain subsets of the input tokens where each token travels down a path (or more than
    one?) determined by a case statement. (can be thought of as being implemented via -->[branch]--*>[filter])
  - **StateSwitch**: input tokens get fed to output stream depending on the last given token from a different input
    stream.

* Generic custom `Junction`s: Implementing a Junction node requires that it has to actively use actor-like semantics
  (including timeouts and possibly polling multiple streams) to request tokens on the input streams. [implemented by the
  fact that in reality it is waiting on all streams at all times, and then decides whether it applies to the given wait
  condition].


### Application / Runtime ################################


#### Nodus Application Specification

_(could have just as easily been named 'Stream Processing Graph' or 'Nodus Application Specification', ...)_

Technically a normal node that happens to:

  * Have neither inputs nor (maybe?) outputs
  * Contain one or more initial generating nodes
  * (therefore) allows execution by the `nodus` execution engine

In practical terms, it:

  * Creates a stream which can then potentially create other streams
  * Ends with explicit or implicit sinks/end-points/reductions
  * Is "executable" in a standalone fashion
  * Is generally behave as a steady-state daemon processing a hypothetically infinite stream of tokens
  * Is usually specified at least at the highest level in a ".node" file that also describes its high-level purpose
  * (in other words) is the top-most specification of a nodus, an Application.
  * Will leave side-effects / external actions for the sinks
  * Will finish by having executed the external action, outputting a reduced/folded result (not ideal since it
    implies batch-like single-run behavior rather than daemon-like), or persisting the final tokens (or a form
    thereof) in a Decoupler (persistent store separate from caches described shortly).

#### File/spec hierarchy, auto-loading, paths, ... (node-language agnosticism?)



#### Nodus Execution Engine (`nodus` command)

  * Parses/processes a nodus specification/application/standalone-process-graph
  * Starts everything up for the nodus and (normally) daemonizes
  * /etc/init.d-(etc.)-like daemon instance management
  * Erlang-like server behavior, ideally (or maybe even actually running on a distributed OTP network...)
  * Could eventually conceivably evolve into tools with higher levels of management/abstraction (for distributed
    processing and cluster management, for example)

#### Application Groups

  * Ability for nodus to specify which applications should be running autonomously all the time (system-level
    daemonized), including restart policy and footprint monitoring vs. those that are experimental / dev / transient,
    vs. those that are something in-between.




---

Scratch
--------------------------------------------------------------------------------------------------


Token: any object instance but usually openstruct with hash-like access as well (so like HashWithIndifferentAccess) but with
WRITE-ONCE semantics! (throws error if the same process/node tries to write the same field a second time)

suggested behavior:
  - lock-field-value-on-write
  - unlock-all-field-values (for when a node starts its turn | possibly specify that this proc/node is one that can write to it)
  - exception on rewrite of a field after it's locked
  -

Contributing
-------------------------------------------------------------------------------------------------

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Ensure that it is accompanied with tests.
* Please try not to mess with the Rakefile, version, or history etc. If you want to have your own version, or it is
  otherwise necessary, then fine, but please isolate to its own commit so I can cherry-pick around it.



Copyright
-------------------------------------------------------------------------------------------------

Copyright (c) 2014 Joseph Wecker. MIT License. See LICENSE.txt for further details.
