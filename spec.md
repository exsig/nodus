

* name (original)
* desc (description name in context of a group, or name by which it is thereafter registered as)
* parameterization
* number of input streams
* number of output streams



    Node[node<n,n>]            => node<n,n>     # (ident)
    Node[desc, node<n,n>]      => node<n,n>     # duplicate, but with a new name
    Node[desc, object]         => node<0,1>     # makes generator node out of enumerator (each)
    Node[desc, name]           => node<n,n>     # aliases a node

    Node[desc, lambda_or_proc] => node<0..1,1>  # arity on lambda simply unpacks array with arity check
    Node[desc]{ ... }          => node<0..1,1>  # arity on block works just like enumerators etc.
    
    Sink[desc]{ ... }          => node<1,0>     # block must have arity of 1 or more- first arg is always state. must pass updated state as result of the block run
                                                # OR just allow some specialized @state object (initialized somehow?)




## Generator Nodes with single stream output


    # Implied
    def registered_name(*params)
      Nodus.lookup(registered_name, *params)
    end

    registered_name(*params).as(contextual_name)  # .as method simply appends to the name-chain (where the last member gets used by default) and returns the resulting node

    # ?? necessary anymore?
    nodelib(registered_name)
    nodelib(registered_name, *parameters)
    nodelib(registered_name, as: contextual_name, *parameters)



    node(name){...}                        # warn on conflict with registered-name? implicit looping?
    node(name, initial_state){|state| ...} # ditto



- name of registered node for lookup
- name for current context (already good default for anything looked-up, very important for lambdas etc.)
- initial-state/parameters
- kernel (as proc, block, lambda, class, or object- not very relevant for registered node lookups)



register node (?? necessary?)
  * `node.register_as(:name)` or `node.register_as([:chain,:of,:names])`
  * looks in `LIB_NODUS_NODE_PATHS` paths for modules/classes and maps to names

look-up & parameterize registered node:

look-up, parameterize, and rename registered node:
