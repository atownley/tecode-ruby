#--
######################################################################
#
# Copyright 2005-2016, Andrew S. Townley
#
# Permission to use, copy, modify, and disribute this software for
# any purpose with or without fee is hereby granted, provided that
# the above copyright notices and this permission notice appear in
# all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHORS DISCLAIM ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS.  IN NO EVENT SHALL THE
# AUTHORS BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# File:     xml.rb
# Author:   Andrew S. Townley
# Created:  Mon Nov 23 22:40:51 GMT 2009
#
######################################################################
#++

require 'rexml/xpath_parser'

module TECode
module XML

  # This class uses the REXML XPath parser (so we didn't have
  # to write one) to provide XPath support to this module.
  # The code is *heavily* based on the rexml/xpath_parser.rb,
  # but it adapts it to work with our simple XML nodes and
  # removes some of the functionality that we don't currently
  # support.

  class XPathLocator
    def initialize
      @parser = REXML::Parsers::XPathParser.new
      @self_only = false
    end

    def find(xpath, node, ns = nil)
      path_stack = @parser.parse(xpath)
#      puts "xpath => '#{xpath}'; stack => #{path_stack.inspect}"
      match(path_stack, node, ns)
    end

    def find_first(xpath, node, ns)
      nodes = find(xpath, node, ns)
      if nodes.size > 0
        return nodes[0]
      end
      nil
    end

  private
    # This method attempts to match nodes in the tree rooted
    # at the node argument against the XPath expression stack
    # parsed by the XPath parser.
    #
    # Unlike the REXML version which seems to remove nodes
    # that don't match, this method attempts to find nodes
    # that actually match the expression and collect them into
    # the nodeset result.
    #
    # NOTE:  We don't really support all the node types
    # possible.
    
    def match(stack, node, ns, nodeset = [])
#      puts "---"
#      puts "node: #{node.prefix.inspect}:#{node.qname.inspect}"
#      puts "ns: #{ns.inspect}"
#      puts "match stack: #{stack.inspect}"
#      puts "nodeset: #{nodeset.inspect}"

      case(op = stack.shift)
        when :any
          # should be fine with this one

        when :attribute
          case stack.shift
            when :qname
              prefix = stack.shift
              qname = stack.shift

              if stack.size == 0
#                puts "attributes: #{node.attributes.inspect}"
                if prefix && "" != prefix
                  # prefix must be in the nslist
                  if node.nslist[prefix] && (val = node.attributes[qname])
                    nodeset << val
                  end
                elsif (val = node.attributes[qname])
                  nodeset << val
                end
              end
           end
        
        when :child
          # need to see if we have any children that match the
          # path
          node.children.each do |child|
#            puts "child: #{child.prefix}:#{child.qname}"
            match(stack.clone, child, ns, nodeset)
          end

        when :document
          # if the node has a parent, then it can't be the
          # document, so we can't match the path.
          
          if node.parent
            return nodeset
          end

        when :function, :neg, :variable
          raise ArgumentError, "XPath function evaluation is not currently supported.  Sorry."

        when :literal
          nodeset << stack.shift

        when :namespace
          # FIXME:  we're going to assume we'll match

        when :node, :descendant_or_self
          # Should be fine

        when :self
          # need to process only the immediate children
          @self_only = true

        when :parent
          # Change the context of the node
          node = node.parent

        when :qname
#          puts "qname stack: #{stack.inspect}"
          prefix = stack.shift
          qname = stack.shift

#puts "prefix: #{prefix.inspect}"
#puts "qname: #{qname.inspect}"
#puts "self_only: #{@self_only}"

          if stack.size == 0
            if prefix && "" != prefix
#puts "A"
              if node.nsuri == ns[prefix] && node.qname == qname
#puts "B"
                nodeset << node
              end
            elsif node.qname == qname
#puts "C"
              nodeset << node 
            end
          else
#puts "D"
            if qname != node.qname || \
                (qname == node.qname && ns[prefix] != node.nsuri)
#puts "E"
              stack.clear if @self_only
            end
          end
#          puts "after qname stack: #{stack.inspect}"

        when :predicate
          # we're only going to support very basic operations
          # here, and we don't have proper support for
          # namespaced attributes, etc, etc, etc...
          pred = stack.shift
#          puts "predicate stack: #{stack.inspect}"
          
          case pred[0] 
          when  :eq
            op, lhs, rhs = pred
            if :attribute == lhs[0] && :literal == rhs[0]
              case lhs[1]
              when :qname
                if rhs[1] == node[lhs[3]]
                  nodeset << node
                end
              else
                raise ArgumentError, "XPath predicate [#{op.inspect}, #{lhs.inspect}, #{rhs.inspect}] not supported!"
              end
            else
              raise ArgumentError, "XPath predicate [#{op.inspect}, #{lhs.inspect}, #{rhs.inspect}] not supported!"
            end
          when :attribute
            # FIXME: ignoring the namespace for the
            # attribute for now
            case pred[1]
            when :qname
#              puts "selected attribute value for '#{pred[3]} => #{node[pred[3]]}"
              nodeset << node[pred[3]]
            else
              raise ArgumentError, "XPath predicate #{pred.inspect} not supported!"
            end
          else
            raise ArgumentError, "XPath predicate #{pred.inspect} not supported!"
          end

        when :text
#          puts "text stack: #{stack.inspect}"
#          puts "selected node text '#{node.qname}' => #{node.text}"
          nodeset << node.text

        else
          raise ArgumentError, "XPath path operator '#{op}' unknown!"
      end

      if stack.size > 0
        match(stack, node, ns, nodeset)
      end
      nodeset
    end

  end

end
end
