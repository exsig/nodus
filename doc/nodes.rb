
# | Node        | Input  | Output |
# | ----------- | ------ | ------ |
# | Processor   | 1/1    | 1/1    |
# | View        | 1/1    | 1/1    |
# | Generator   | 1/0    | 1/1    |
# | Branch/Tap  | 1/1    | 1/n    |
# | Recombine   | 1/n    | 1/1    |

# | Set         | 0/0    | n
# | Projection  | 1/1    | 1b/1b  |
# | Sink        | 1/1    | 1b/1b  |
# | Mux         | n/n*1  | 1/1    |
# | Zip         | n/n*1  | 1/1    |
# | Switch      | 1/1    | n/n*1  |
# | StateSwitch | 2/2*1  | n/n*1  |
# | Junction    | n/m    | o/p    |


class Node
  attr_reader :dot_style, :name
  def initialize(name)
    @name = name
    @style_attrs = {}
    style :shape,     :circle
    style :fontname,  'Helvetica'
    style :color,     '#222222'
    style :fontcolor, '#444444'
  end

  def style(k,v)
    @style_attrs[k] = v.to_s
  end
end

class RootNode < Node
  # (override how it's displayed)
  # one or more g
end

class StandaloneNode < Node
  # Starts with a generator
end

class Generator < Node
  def initialize(*)
    super
    style :shape,       :trapezium
    style :orientation, 270
    style :style,       :filled
    style :fillcolor,   '#CCEEDD'
  end
end


class Branch < Node
  def initialize(*)
    super
    style :shape,       :triangle
    style :orientation, 90
    style :style,       :filled
    style :fillcolor,   '#EEDDCC'
    style :label,       ''
  end
end

class Merge < Node
  def initialize(*)
    super
    style :shape,       :triangle
    style :orientation, 270
    style :style,       :filled
    style :fillcolor,   '#EEDDCC'
    style :label,       ''
  end
end

