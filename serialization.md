
| serialization format | integer | float | atom | tuple | list | binary | string | nil | bool | dict  | record | union | time  | extend |
|
| bert                 | Y       | Y     | Y    | Y     | Y    | Y      | 4      | 1   | 1    | 2     | 5      | 9     | 3     |        |
| messagepack          | Y       | Y     |      |       | Y    | Y      | Y      | Y   | Y    | Y     |        |       | 8     | Y      |
| bson                 | Y       | Y     |      |       | Y    | Y      | Y      | Y   | Y    | Y     |        |       | Y     |        |
| avro                 | Y       | Y     | 6    |       |      | Y      | Y      | Y   | Y    | Y     | Y      | Y     | 7     | 7      |
| thrift
| protocol buffers
| json



1. via atom
2. via list of tuples
3. via tuple
4. via list of bytes or binary
5. via tuple of tuples
6. aka enum
7. via fixed
8. via extend
9. implicit (?) a | in erlang's type definition



scalars (uncommon: atom/enum)


| container   | fixed size? | index type  | contains     | aka (sometimes w/ different runtime properties) |

| set         | no          | ident       | membership   | tree
| map         | no          | ident       | homogenous   | dict, obj, assoc-array |

| record      | yes         | ident       | heterogenous | obj, struct |
| tuple       | yes         | position    | heterogenous | 
| array       | no          | position    | homogenous   | tree
| list        | no          | position    | heterogenous | vector


fixed size: yes | no
index type: ident | position
contains:   homogenous | heterogenous | membership


| no  | ident    | hom    | map
| no  | position | hom    | vector
| no  | ident    | het    |
| no  | position | het    | list
| no  | ident    | mem    | set
| no  | position | mem    | range

| yes | ident    | hom    |
| yes | position | hom    |
| yes | ident    | het    | record/struct
| yes | position | het    | tuple
| yes | ident    | mem    |
| yes | position | mem    | bitmask


