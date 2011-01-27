#--
######################################################################
#
# Copyright 2009-2011, Andrew S. Townley
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
# File:     simple_mapper.rb
# Author:   Andrew S. Townley
# Created:  Thu 27 Jan 2011 17:48:18 GMT
#
######################################################################
#++

module TECode
module XML

  # This class makes it extremely easy to process single-level
  # elements commonly seen in database table exports or
  # similar situations.  This class will collect all of the
  # immediate child elements of the specified element and make
  # them available as a nested hash through the data instance
  # variable.
  #
  # For example, given the following XML:
  #
  # <?xml version="1.0"?>
  # <root>
  #   <child1>Foo</child1>
  #   <child2 bar="baz"/>
  #   <child3 lang="en">FUBAR</child3>
  # </root>
  #
  # The data may be extracted using the following API
  #
  # File.open("input.xml", "r") do |f|
  #   mapper = SimpleMapping.element("root").parse(f.read)
  #   pp mapper.data
  # end
  #
  # resulting in:
  #
  # {"child1"=>"Foo",
  #  "child2"=>{"bar"=>"baz"},
  #  "child3"=>{"lang"=>"en", :text=>"FUBAR"}}
  #
  # Namespaces are just as easy:  simply specify the namespace
  # URI after the element name, e.g.:
  #
  # <?xml version="1.0"?>
  # <root xmlns="http://xmlns.com">
  #   <child1>Foo</child1>
  #   <child2 bar="baz"/>
  #   <child3 lang="en">FUBAR</child3>
  # </root>
  #
  # File.open("input.xml", "r") do |f|
  #   mapper = SimpleMapping.element("root", "http://xmlns.com").parse(f.read)
  #   pp mapper.data
  # end
  #
  # resulting in:
  #
  # {"child1"=>"Foo",
  #  "child2"=>{"bar"=>"baz"},
  #  "child3"=>{"lang"=>"en", :text=>"FUBAR"}}
  
  class SimpleMapper
    include Mapping
    attr_accessor :data

    def initialize(options)
      @data = {}
    end

    def self.element(qname, ns = nil)
      if ns
        namespace ns
      end

      mapping qname do
        on_end_element do |mapper, my|
          my.children.each do |node|
            if node.has_attributes?
              x = mapper.data[node.qname] = {}
              node.attributes.each do |key, val|
                x[key] = val
              end
              if "" != (s = node.text.strip)
                x[:text] = s
              end
            elsif "" != (s = node.text.strip)
              mapper.data[node.qname] = s
            end
          end
        end
      end
      
      self
    end
  end

end
end
