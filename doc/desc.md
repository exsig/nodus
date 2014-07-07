




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

(every node can be one or more of the following):

- **Generator** - outputs to one or more streams not present as inputs
- **Consumer**  - gets input from one or more streams not present as outputs
- **Processor** - has at least one input stream that is present as an output stream as well

(not sure if that is a useful taxonomy...)

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


**DataMap** = Multiply + Concurrent(Filter or Select, View, Node) + Join



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
