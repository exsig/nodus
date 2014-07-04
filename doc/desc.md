


Data Parallelism
----------------

| Node Type   | In/Out  | AKA                       |
| ----------- | ------- | ------------------------- |
| Computation | 1=a/1=a | Process, Element, ...     |
| DataMap     | 1=a/1=a | (Branch+Execute+Merge)

| Fork



Computation(kernel/1|Node) # needs to be sent tokens. Outputs tokens.
Generator  (kernel/0|Node) # 
DataMap(brancher/1, Executor::Node, merger/\*)
Fork()


As first token propagates, it's stream-id propagates with it. Nodes that are vertically stateful and therefore need to
guarantee that the same stream is feeding them tokens at all time then use it for comparison.




Lifecycle
  - if it has non-delayed parameterization, it spawns and sets its parameters
  - it can be given the output node at creation time, parameterization-time, or any time (even after it has received tokens from
    at least one inbound stream) before it tries to emit a token on that stream. 
  - internal state machine runs until it needs its first token (if applicable) (or until it's output queue fills up too
    much)
  - proceeds to run state machine



Compose Classes or Instances (or both)??




