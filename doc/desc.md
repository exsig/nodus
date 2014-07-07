




Composition Rules
-----------------

Compositions should be parameterized one way or another- built dynamically and allowing for variable interpolation.

Most composition nodes are given a `NodeList`, which consists of either:
  * An ordered list of nodes (although order doesn't always matter)
  * OR, a design-time function that calculates the list of nodes
  * OR, a run-time function that calculates the list of nodes depending on token data (in which case we need to require
    some sort of template / worst-case scenario etc. so that we can determine composition at a higher level? or maybe a
    range specifier?)
  * (with port-specifiers for individual nodes if necessary)

- Data Handler
- Upstream Exception Handler
- Downstream Exception Handler ?
- OOB Message Handler (such as N/A)

### Core Custom Node

#### Port types:

##### Inputs
  - **parameter**(default=nil): w/ optional default... specialized optional or required input port (probably not
    implemented as actual message channel). Also possibly enforce the fact that it can't be connected to a stream.
    Possibly composable / or able to be overridden kind of in parallel to other compositions. **optional** or
    **required**. *These are also outputs. i.e., they are readable.*
  - **operational**(out-port): port has paired output port that is stream-synchronized with this input.
  - **control**: specialized end-point used to help node make decisions. e.g., state / out-of-band messages
  - **end-point**: Consumed / Sink. Node reads input but doesn't have corresponding synchronized output.

##### Outputs
  - **operational**(in-port): port has paired input port and this output adds to (or passes through) those input tokens.
  - **tap-point**: Output port that can optionally be tapped into (usually meaning it already has a listener within the node).
  - **controller**: ??? not sure if it's a worthwhile distinction- but outputs that are meant to be read as control
    inputs. *Implies also generated*?
  - **generated**: Origins. Node generates stream / it has no corresponding input port.

#### Helpers

 - **Simple Generator**
 - **Simple Processor**
 - **Simple Consumer** = **Simple Fold**
 - **Simple Projection**

Most accept one or more kernels (== `lambda`, `proc`, `block`, or misc. `class` constant with specific handlers/behavior)

### Axiomatic

**Node:**
  * I=0..n (input ports) and O=0..n (output ports). Most of the time a static number, but sometimes a range of available
    ports.

**Connector:**
  * *AdHoc*
  * Given an arbitrary list of nodes, allows specifying connection pairs between available inputs/outputs.
  * Result is a node with all remaining unconnected input and output ports

**Pipe:**
  * *AdHoc*
  * Connects member nodes on specified or default ports (specialized connector)
  * All member nodes except last must have at least one output
  * All member nodes except for first must have at least one input
  * (like connector) result defined by unconnected inputs/outputs (usually just one main input and one main output)

**Concurrent:**
  * *AdHoc*
  * Executes members concurrently. Input & output streams are all inputs and outputs of members.

**Join:**
  * *Stream-Synchronized*
  * Token aware- meant to merge parallel branches of a single stream
  * Unlimited input connections
  * Listens for NOPs

**Multiply:**
  * *Stream-Synchronized*
  * Single input port split into specified number of output ports
  * Each branch (implicitly?) has its own parallel context on the token

**View:**
  * *Stream-Synchronized*
  * Given a token, select a different set of fields to be the current context for downstream nodes

**Filter:**
  * *Stream-Synchronized* (NOP) OR *Projection* (Drop)
  * Drop or NOP tokens matching certain criteria

**Select:**
  * *Stream-Synchronized* (NOP) OR *Projection* (Drop)
  * Drop or NOP tokens not matching certain criteria

### Composites


**MultiMap**
  * Multiply + Concurrent(Filter or Select, View, Node) + Join

**Mux** (multiplex)
  * *AdHoc* to *Stream-Synchronized*
  * Multiple input streams
  * Output token for each input token on _any_ input stream

**Tap**
  * *Stream-Synchronized*
  * A Multiply, but defined differently so that it can be injected in another node (?) without changing that node's
    functionality.
  * Specify tap-point of other-node when constructing.

**Runner**
  * Usually automatically created
  * Wraps a list of nodes into concurrent. Any inputs given stdin or integer sequences (?) and all outputs are
    multiplexed to stdout.

**StateSwitch**
  * Has a state port and various output streams- state port helps it decide which filter/select branches are chosen
    (allow either drop or nop?)

**Split**
  * Multiply + Concurrent(Filter or Select [with DROP], View, (optional Node))
  * Like MultiMap except non-matching records are dropped- effectively creating unique streams

As first token propagates, it's stream-id propagates with it. Nodes that are vertically stateful and therefore need to
guarantee that the same stream is feeding them tokens at all time then use it for comparison.


Scratch
--------

Instead of streams / branches maybe just dynamic recognition of which channels have something other than a 1:1
input/output token ratio? I.e., which streams are totally synchronous so to speak...

Lifecycle
  - if it has non-delayed parameterization, it spawns and sets its parameters
  - it can be given the output node at creation time, parameterization-time, or any time (even after it has received tokens from
    at least one inbound stream) before it tries to emit a token on that stream.
  - internal state machine runs until it needs its first token (if applicable) (or until it's output queue fills up too
    much)
  - proceeds to run state machine



Compose Classes or Instances (or both)??
