require 'securerandom'

module Nodus
  class GraphContext
    def initialize(name='Nodus process network')
      @name = name
    end
  end

  class Node
    def style(k,v)
      style_attrs[k] = v
    end

    def style_attrs
      @style_attrs ||= {shape:     :circle,
                        fontname:  'Helvetica',
                        color:     '#222222',
                        fontcolor: '#444444'}
    end

    def to_dot(depth=0)
      before_render() if self.respond_to?(:before_render, true)
      
      style_attrs[:label] ||= self.name
      out = ["#{dot_name} #{dot_attrs};"]
      inputs.select(&:unbound?).each do |i|
        blank, blank_def = new_blank_node
        out << blank_def
        out << "#{blank} -> #{dot_name} [label=\"#{i.name}\"];"
      end
      outputs.each do |o|
        if o.unbound?
          dest, dest_def = new_blank_node
          out << dest_def
          dests = [dest]
        else
          dest_nodes = o.branches.flat_map{|nm,br| br.subscribers.map{|s| s.parent_node}}
          #dest_nodes.each{|n| out << n.to_dot(1) }
          dests = dest_nodes.map{|n| n.dot_name}
        end
        dests.each{|d| out << "#{dot_name} -> #{d} [label=\"#{o.name}\"];"}
      end

      out = [wrap_start, out, wrap_end] if depth==0
      
      out.join("\n")
    end

    def dot_name() @dot_name ||= "\"##{self.object_id}\"" end

    protected def new_blank_node()
      name = "\"##{SecureRandom.uuid}\""
      attr = ' [ color="#ffffff", label=" ", style=filled ]'
      [name, name + attr + ';']
    end
    protected def dot_attrs() '[ ' + style_attrs.map{|k,v| "#{k}=\"#{v}\""}.join(',') + ' ]' end
    protected def wrap_start
      <<-QUOTE
        digraph "#{name}" {
          graph [ rankdir=LR ];
          edge  [ arrowsize=0.5, color="#222222" ];
          rank=source;
          compound=true;
          color="#444444";
      QUOTE
    end
    protected def wrap_end() '}' end
  end
end
