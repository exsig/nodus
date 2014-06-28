Nodus
============================================================================================================================

_(WARNING: EXPERIMENTAL)_

## Description

Framework for [parallel](http://en.wikipedia.org/wiki/Parallelization)
[data-flow](http://en.wikipedia.org/wiki/Dataflow) based applications.


It is influenced by and similar to:

 * [Kahn Process Networks](http://en.wikipedia.org/wiki/Kahn_process_networks)
 * [Algorithmic Skeletons](http://en.wikipedia.org/wiki/Algorithmic_skeleton) (see also [here](https://github.com/ParaPhrase/skel))
 * [Iteratee IO](http://okmij.org/ftp/Streams.html)
 * And of course the hundreds of other reinventions with names like
   `/(((data|signal|packet)?(stream|flow)|pipe(line)?|(flow|event|signal|reactive)-(processing|programming|architecture|computing|language)/`
   combined with parallelization, concurrency, clustering paradigms, etc. etc...





Components
------------------------------------------------------------------------------------------------------------------------------

### Data #############################################

| Thing     | Otherwise Known As |                                                    |
|-----------|--------------------|----------------------------------------------------------|
| Stream    | Flow, Signal                  | Related ordered data representation- bundled into tokens (chunks). A gradually consumed state |
| Token     | Chunk, Element, Event, Sample | Coherent instance of stream data being mutated and passing through the pipelines (potentially in parallel) - special values of EOF & Exceptionals |

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
Generally though most nodes will deal with only a single stream- and most of those will be operators, with a generator
at the beginning and a sink at the end.

| Aspect     | Otherwise Known As  |   |
|------------|---------------------|---|
| Generator  | Source, Origin, Enumerator, Producer, Start | Has one or more output streams that originate there & are not among its incoming streams (although the incoming streams may have participated in its creation). |
| Consumer   | Sink, Iteratee, Fold, Reducer, End | folds over one or more input streams & emits nothing except a final result/stats if the done/EOF token is encountered. Usually in charge of any external side-effects. |
| Processor  | Filter, Enumeratee, Operator, Function, Convolution, Transformer | Receives a token from a stream and either passes it through or advances its state before outputting the same stream-type. |

#### Generators

#### Consumers

A stream endpoint. Not referring to the fact that they simply accept tokens- but to the fact that once accepted they do
not emit any more for that stream, it having been consumed.

#### Processor



#### Nexus / Decoupler Consumers


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



---- overkill ----
Generator from simple-proc
Generator from Enum
Generator from Lazy Enumerator
Generator from basic class
Generator from basic class via to_enum
Generator from state-machine
Generator from DSL

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
