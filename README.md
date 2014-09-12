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


-  Guiding philosophies
  - [ ] Steady-state
  - [ ] Composable
  - [ ] Proportionate
  - [ ] Real-time & simulation-time
  - [ ] Resilient (failure modes as first class features, exception/failure paths, bulkheads, circuitbreakers, hibernation, ...)
- Simple single-stream sequential
  - [ ] URI-like notation
  - [ ] Token state accumulation
- Single-stream sequential with explicit sink
- Single-stream parallel
  - [ ] Branches
  - [ ] Forks
  - [ ] Waypoints
  - [ ] Pattern Branching
- Multi-stream
- Getting away with duck-typing



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
