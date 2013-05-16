#--
######################################################################
#
# Copyright 2009, Andrew S. Townley
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
# Created:  Fri Apr 17 13:24:45 IST 2009
# Updated:  Tue Nov 24 11:02:50 GMT 2009
#
######################################################################
#++

require 'xml'

module TECode
module XML

  # This class represents an XML node, with full namespace
  # support.

  class SimpleNode
    attr_accessor :nsuri, :qname, :attributes 
    attr_accessor :children, :text, :prefix, :nslist, :parent, :vars

    def initialize(qname, attrs, nsuri = nil, prefix = nil, nslist = nil)
      @qname = qname
      @attributes = attrs
      @nsuri = nsuri
      @prefix = prefix
      @nslist = nslist
      @text = ""
      @children = []
      @parent = nil
      @locator = TECode::XML::XPathLocator.new
      @vars = {}

      if nsuri && !nslist.values.include?(nsuri)
        nslist[prefix] = nsuri
      end
#      puts "nslist for #{qname}: #{nslist.inspect}"
    end

    def find(xpath, nslist = self.nslist)
      @locator.find(xpath, self)
    end

    def find_first(xpath, nslist = self.nslist)
      @locator.find_first(xpath, self)
    end

    def [](key)
      attributes[key]
    end

    def has_children?
      children.size > 0
    end

    def has_attributes?
      @attributes.size > 0
    end

    def to_xml
      s = "<"
      if @prefix
        s << @prefix << ":"
      end
      s << qname
      if @attributes.size > 0
        @attributes.keys.sort.each do |k|
          s << " " << k << "=\"" << @attributes[k] << "\""
        end
      end
      s << ">" << text
      children.each { |c| s << c.to_xml }
      s << "</"
      if @prefix
        s << @prefix << ":"
      end
      s << qname << ">"
    end

  end

  # This class provides a default message handler

  class StdMessageHandler
    def warn(str)
      STDERR.puts("warning: #{str}")
    end

    def err(str, abort = false)
      STDERR.puts("error:  #{str}")
      if abort
        exit(abort)
      end
    end

    def puts(str)
      puts str
    end
  end

  # This module defines classes and methods to help
  # automatically generate XML to object mappings that have
  # full support for XML namespaces.

  module Mapping

    def self.included(base)
      base.instance_variable_set("@mappings", {})
      base.extend ClassMethods
    end

    module ClassMethods
      def mapper_class=(klass)
        @mapper_class = klass
      end

      def mapper_class
        @mapper_class || ElementMapping
      end

      def mappings
        @mappings
      end

      def default_nsuri
        @default_ns
      end

      def namespace(nsuri)
        @default_ns = nsuri
      end

      def mapping(*args, &block)
        if args.length == 1 && args[0].is_a?(Hash)
          qname = args[0].delete(:tag)
          if qname.nil? && args[0][:xpath].nil?
            raise ArgumentError, "one of a tag name (either arg[0] or :tag => TAGNAME) or an xpath value (:xpath => XPATH) must be specified!"
          end
          mapping = self.mapper_class.new(qname, args[0])
        else
          mapping = self.mapper_class.new(*args)
        end
        mapping.instance_eval(&block) if block_given?
        @mappings[mapping.qname] = mapping
      end

      def parse(str, options = {}, msgs = StdMessageHandler.new)
        if str.is_a? String
          parser = ::XML::SaxParser.string(str)
        elsif str.is_a? StringIO
          parser = ::XML::SaxParser.io(str)
        end
        mapper = self.new(options)
        parser.callbacks = SaxHandler.new(self, msgs, mapper)
        parser.parse
        mapper
      end
    end

    # This class represents a single element mapping instance.

    class ElementMapping
      attr_accessor :qname, :nsuri, :xpath, :ns_regex
      attr_accessor :start_proc, :end_proc, :properties

      def initialize(qname, options = {})
        @qname = qname
        @xpath = ""
        @options = options
        @start_proc = nil
        @end_proc = nil
        @properties = {}
        @property_mapping = {}

        # set the possible default options
        xpath(options[:xpath])
      end

      # By default, the mapping is triggered whenever the
      # QName of the node matches the qname of the mapping.
      # To restrict this behavior, use this method to specify
      # the XPath when this mapping should be triggered
      # instead.

      def xpath(str)
        @xpath = str
      end

      # Set the namespace URI for this node

      def namespace(nsuri)
        @nsuri = nsuri
      end

      # For multi-versioned schemas where the element is the
      # same across multiple instance documents, you may
      # specify a regex match for the namespace.

      def namespace_regex(regex)
        if regex.is_a? String
          @ns_regex = Regexp.new(regex)
        elsif regex.is_a? Regexp
          @ns_regex = regex
        else
          raise ArgumentError, "regex must be a string or a regexp instance"
        end
      end

      def property_mappings?
        @property_mapping.size > 0
      end

      # Set the block that will execute when the mapping is
      # matched.  The parameters to the block will be:
      #
      #   self, node

      def on_start_element(&block)
        @start_proc = block
      end

      # Set the block to be executed when the closing element
      # tag is found.  The parameters will be:
      #
      #   self, node

      def on_end_element(&block)
        @end_proc = block
      end

      # This method registers a property setter XPath value to
      # be automacially run when the SAX end element event is
      # triggered for this mapping.

      def property(key, xpath = nil, nslist = {})
        if !xpath
          # we assume that the property comes from a child
          # element's text node
          xpath = "./#{key}/text()"
        end
        @property_mapping[key] = [ xpath, nslist ]
      end

      def [](key)
        @properties[key]
      end

      def []=(key, val)
        @properties[key] = val
      end

      def set_properties(mapper, node)
        @property_mapping.each do |k,v|
          self[k] = node.find(v[0], v[1])
#          puts "self[#{k}] = #{self[k].inspect}"
        end

        if mapper.respond_to? :mapping_handler
          mapper.mapping_handler(self, node)
        end
      end
    end

    # This class provides all of the required SAX-based
    # callbacks to do event-driven parsing of the XML input

    class SaxHandler
      attr_reader :stack

      def initialize(mapper, messages, instance)
        @stack = []
        @mapper = mapper
        @messages = messages
        @instance = instance
      end

      def on_cdata_block(cdata)
#        @messages.warn "ignoring CDATA block: #{cdata}"
        stack[-1].text << cdata
      end

      def on_characters(chars)
        stack[-1].text << chars
      end

      def on_comment(text)
      end

      def on_end_document
      end

      def on_error(error)
        @messages.err error
      end

      def on_processing_instruction(target, data)
        @messages.warn "ignoring processing instruction #{target} #{data}"
      end

      def on_start_document
      end

      def on_start_element(qname, attributes)
      end

      def on_end_element(qname)
      end

      def on_start_element_ns(qname, attributes, prefix, uri, nslist)
#        puts "attributes: #{attributes.inspect}"
#        puts "nslist: #{nslist.inspect}"
        parent = stack[-1]
        node = SimpleNode.new(qname, attributes, uri, prefix, nslist)
        if parent
          parent.children << node
          node.parent = parent
          node.nslist = node.nslist.merge(parent.nslist)
        end
        stack << node

        mapping = mapping_for(stack, qname, uri, nslist)
        if mapping && mapping.start_proc
          mapping.start_proc.call(@instance, node)
        end
      end

      def on_end_element_ns(qname, prefix, uri)
        node = stack[-1]
        mapping = mapping_for(stack, qname, uri, node.nslist)
        if mapping
          if mapping.end_proc
            mapping.end_proc.call(@instance, node)
          elsif mapping.property_mappings?
            mapping.set_properties(@instance, node)
          end
        end
        stack.pop
      end

      def on_external_subset(name, external_id, system_id)
        @messages.warn "ignoring external subset #{name} #{external_id} #{system_id}"
      end

      def on_has_external_subset
      end

      def on_has_internal_subset
      end

      def on_internal_subset(name, external_id, system_id)
        @messages.warn "ignoring internal subset #{name} #{external_id} #{system_id}"
      end

      def on_is_standalone
      end

      def on_reference(name)
        @messages.warn "ignoring reference #{name}"
      end

    private
      def mapping_for(stack, qname, nsuri, nslist)
        mapping = @mapper.mappings[qname]
        if mapping && (mapping.nsuri == nsuri \
            || nsuri == @mapper.default_nsuri)
          return mapping
        elsif mapping && (rx = mapping.ns_regex)
          return mapping if rx.match nsuri
        end
        nil
      end

      def dump_stack
        s = "STACK: "
        stack.each do |node|
          s << node.qname
          s << ", " if node != stack[-1]
        end
        puts s
      end
    end
  end
end
end
