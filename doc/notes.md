



### processing node / chain
  - simple lazy enumerable - or even extension of enumerables so that it can easily be chained simply with the dot notation
  - define overall endpoint (a stream object) @ combination of creation-time/run-time
  - connect via some kind of query (etc.) to existing stream object as input @ run-time
  - decoupled from streams such that they can live and die without the streams caring
  - can wait for any amount of time for an incoming stream(s) to be created or become available
  - different input ports can be connected to different stream channels (but only one on each input port)
  - maintain their own function-dependent state separate from stream-state (which they can also output to the
    output-stream of course if they think it'll be relevant)

### streams
  - singletons (per name/uri)
  - one of: transient+anonymous, transient+defined, persisted+defined
  - any number of inputs / generators (although some collision maintenance might be necessary)
  - possibly determine how many records to hold / what kind of queries available - esp. if transient

  - possibly define the actor/process/server to launch to populate values if they are/will-be needed, which
    automatically happens if there isn't one running already.

### misc

  - gaps possibly automatically cause session gaps further downstream- launch completely new processing chain





* Allows sections with somewhat permanent staging states to be built independently and incrementally.
* Doesn't harm the end-to-end online-ness of the eventual system
* Unifies historical & live processing
* Allows for clean separation of true pure intrinsic features vs strategy/algorithm-specific paths such as machine
  learners or latent feature discovery systems
* Allows for easily destroying persistent data from later stages that isn't relevant/correct/etc.
