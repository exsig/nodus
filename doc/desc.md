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

Most accept one or more kernels (== `lambda`, `proc`, `block`, or misc. `class` constant with specific handlers/behavior)

If a class handler, it will probably want to implement one or more of:
  - Data Handler
  - Upstream Exception Handler
  - Downstream Exception Handler ?
  - OOB Message Handler (such as N/A)

### Core Custom Node

#### Port types:

`parameter: (optional[<default>] | required)`

`| input:  (operational<output-port[s]> | consumed  [control]) x (optional | required)`

`| output: ( operational<input-port[s]> | generated [control]) x (tap      |  primary)`



##### Parameters
  - **parameter**(default=nil): w/ optional default... specialized optional or required input port (probably not
    implemented as actual message channel). Also possibly enforce the fact that it can't be connected to a stream.
    Possibly composable / or able to be overridden kind of in parallel to other compositions. **optional** or
    **required**. *These are also outputs. i.e., they are readable.* In fact they are intrinsicly different than normal
    ports because they must be set before any real data comes through the node.

##### Inputs
  - **operational**(out-port[s]): port has paired output port that is stream-synchronized with this input.
  - **control**: specialized (and implied) end-point used to help node make decisions. e.g., state / out-of-band messages
  - **consumed**: End-point / Sink. Node reads input but doesn't have corresponding synchronized output.
  - **optional**: Node can run without this being connected to anything (although not sure if they can connect at some
    later point in time...)

##### Outputs
  - **operational**(in-port[s]): port has paired input port and this output adds to (or passes through) those input tokens.
  - **controller**: Specialized (and implied) generated port used to help other nodes make decisions. Also state & out of band messages.
  - **generated**: Origin / Generator. Node generates stream / it has no corresponding input port.
  - **tap-point**: Output port that can optionally be tapped into (usually meaning it already has a listener within the node).


#### Helpers / Quick Builders

 - **Simple Generator**
 - **Simple Processor**
 - **Simple Consumer** = **Simple Fold**
 - **Simple Projection**

### Axiomatic

**Node:**
  * I=0..n (input ports) and O=0..n (output ports). Most of the time a static number, but sometimes a range of available
    ports.

**Connector:**
  * *AdHoc*
  * Given an arbitrary list of nodes, allows specifying connection pairs between available inputs/outputs.
  * Result is a node with all remaining unconnected input and output ports
  * Can also connect values to parameter inputs
  * Essentially a curry function

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


Phases
1. Kernel-design time:
   - designate input/output ports/streams
2. Design-time:
   - specify bindings as much as possible
   - compose
   - pre-initialize/parameterize as appropriate
   - specify process network / highest level compositions
3. Pre-runtime:
   - static compliance-check
   - display process network graph
   - warnings / errors as appropriate
4. Runtime:
   - dynamic parameterization as appropriate
   - dynamic running nodes as appropriate
   - contexts and real stream instances


Specialized (out of band) input/output ports
  - new output available
  - new input available (?)
  - output subscribed by...
  - input bound by...

  (allows nodes to communicate in an out-of-band fassion... easier to simply specify the peer object in initialize and
  make sure every node has a general out-of-band communication channel where senders say who they are?)

* Inputs can be bound to only one output
* Outputs can be subscribed to by any number of other nodes
* Binding to a node itself assumes the correct input/output if only one of either is available
