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
# File:     subsumption_tree.rb
# Created:  Thu Oct 20 10:18:16 SAST 2016
#
######################################################################

require 'prime'

# This class manages a generalized subsumption tree.

class SubsTree
  attr_reader :nodes

private
  class EratosthenesSieve
    include Singleton

    BITS_PER_ENTRY = 16  # each entry is a set of 16-bits in a Fixnum
    NUMS_PER_ENTRY = BITS_PER_ENTRY * 2 # twiced because even numbers are omitted
    ENTRIES_PER_TABLE = 8
    NUMS_PER_TABLE = NUMS_PER_ENTRY * ENTRIES_PER_TABLE
    FILLED_ENTRY = (1 << NUMS_PER_ENTRY) - 1

    def initialize # :nodoc:
      # bitmap for odd prime numbers less than 256.
      # For an arbitrary odd number n, @tables[i][j][k] is
      # * 1 if n is prime,
      # * 0 if n is composite,
      # where i,j,k = indices(n)
      @tables = [[0xcb6e, 0x64b4, 0x129a, 0x816d, 0x4c32, 0x864a, 0x820d, 0x2196].freeze]
    end

    # returns the least odd prime number which is greater than +n+.
    def next_to(n)
      n = (n-1).div(2)*2+3 # the next odd number to given n
      table_index, integer_index, bit_index = indices(n)
      loop do
        extend_table until @tables.length > table_index
        for j in integer_index...ENTRIES_PER_TABLE
          if !@tables[table_index][j].zero?
            for k in bit_index...BITS_PER_ENTRY
              return NUMS_PER_TABLE*table_index + NUMS_PER_ENTRY*j + 2*k+1 if !@tables[table_index][j][k].zero?
            end
          end
          bit_index = 0
        end
        table_index += 1; integer_index = 0
      end
    end

  private
    # for an odd number +n+, returns (i, j, k) such that @tables[i][j][k] represents primarity of the number
    def indices(n)
      #   binary digits of n: |0|1|2|3|4|5|6|7|8|9|10|11|....
      #   indices:            |-|    k  |  j  |     i
      # because of NUMS_PER_ENTRY, NUMS_PER_TABLE

      k = (n & 0b00011111) >> 1
      j = (n & 0b11100000) >> 5
      i = n >> 8
      return i, j, k
    end

    def extend_table
      lbound = NUMS_PER_TABLE * @tables.length
      ubound = lbound + NUMS_PER_TABLE
      new_table = [FILLED_ENTRY] * ENTRIES_PER_TABLE # which represents primarity in lbound...ubound
      (3..Integer(Math.sqrt(ubound))).step(2) do |p|
        i, j, k = indices(p)
        next if @tables[i][j][k].zero?

        start = (lbound.div(p)+1)*p  # least multiple of p which is >= lbound
        start += p if start.even?
        (start...ubound).step(2*p) do |n|
          _, j, k = indices(n)
          new_table[j] &= FILLED_ENTRY^(1<<k)
        end
      end
      @tables << new_table.freeze
    end
  end

  class SubsTreeNode
    attr_reader :label
    attr_reader :prime
    attr_reader :subs
    attr_reader :parents
    attr_reader :children

    def initialize(label, pr)
      @label = label
      @prime = pr
      @subs = pr
      @parents = []
      @children = []
    end

    def add_child(node)
      if node.prime < prime
        raise ArgumentError.new("Structure viloation: #{node.label} prime (#{node.prime}) < #{label} prime (#{prime})")
      end

      node.recalc(self)
      @children << node
    end

    def remove_child(node)
      node.unparent(self)
      @children.delete(node)
    end

    def has_parents?
      @parents.size != 0
    end

    def has_children?
      @children.size != 0
    end

    def reset_prime(new_prime)
      old_prime = prime     # 3
      @prime = new_prime    # 23
      @subs = @prime
      parents.each do |p|
        @subs *= p.subs
      end
      children.each do |c|
        if (cp = c.prime) < prime
          c.reset_prime(prime)
          reset_prime(cp)
    #    else
    #      c.reset_prime(cp)
        end
      end
    end

    def ancestors
      ants = parents.clone
      parents.each { |p| ants.concat(p.ancestors) }
      ants.uniq
    end

    def descendants
      desc = [].concat(children)
      children.each { |c| desc.concat(c.descendants) }
      desc.uniq
    end

    def to_s
      s = "[ #{label} (#{@prime}, #{@subs}) ]\n"
      if has_parents?
        s << "parents: "
        s << parents.collect { |p| p.label }.join(", ")
        s << "\n"
      end
      if has_children?
        s << "children: "
        s << children.collect { |c| c.label }.join(", ")
      end
      s
    end

protected
    def recalc(parent)
      @parents << parent if !@parents.include? parent
      @subs = prime
      parents.each { |p| @subs *= p.subs }
      recalc_children
    end

    def unparent(parent)
      @parents.delete(parent)
      @subs = @subs / parent.subs
      recalc_children
    end

    def recalc_children
      children.each { |c| c.recalc(self) }
    end
  end

public

  def initialize
    @last_prime = 1
    @root = SubsTreeNode.new(" - root - ", @last_prime)
    @prime = EratosthenesSieve.instance
    @nodes = { @root.label => @root }
  end

  def add_node(parent, child)
    parent = parent.to_s
    child = child.to_s

    if descendant_of(parent, child)
      raise ArgumentError.new("Cycle detected (#{parent} -> #{child}): #{parent} is already a child of #{child}")
    end

    if (p = @nodes[parent]).nil?
      # need to create a new node in the tree as a child of
      # the master root node
      p = SubsTreeNode.new(parent, next_prime)
      @nodes[parent] = p
      @root.add_child(p)
    end

    if (c = @nodes[child]).nil?
      # then this child doesn't yet exist in the tree, so we
      # need to simply create a new one
      c = SubsTreeNode.new(child, next_prime)
      @nodes[child] = c
    end

    if p.prime < c.prime
      p.add_child(c)
    else
      puts "fix tree - parent(#{p.label}): #{p.prime}; child(#{c.label}): #{c.prime}"
#      # Step 1: unparent the new child
#      c.parents.each { |cp| puts "remove: #{cp.label}"; cp.remove_child(c) }
#      puts "CHILD:"
#      puts c
#      puts "END"

      # Step 2: swap the parent and child primes
      parent_p = p.prime
      child_p = c.prime
      c.reset_prime(parent_p)
      p.reset_prime(child_p)

      # Step 3: add the node to the desired parent
      p.add_child(c)
    end
  end

  def ancestor_of(parent, child)
    if parent = @nodes[parent.to_s]
      ancestors(child).include? parent.label
    else
      false
    end
  end

  def descendant_of(child, parent)
    puts "is '#{child}' child of '#{parent}'?"
    parent = @nodes[parent.to_s]
    child = @nodes[child.to_s]
    
    if parent.nil? || child.nil?
      false
    else
      child.subs % parent.subs == 0
    end
  end

  def remove_child(parent, child)
    parent = @nodes[parent.to_s]
    child = @nodes[child.to_s]

    if parent && child
      parent.remove_child(child)
    end
  end

  def ancestors(node)
    if node = @nodes[node.to_s]
      x = node.ancestors
      x.delete(@root)
      x.collect { |a| a.label }
    else
      []
    end
  end

  def descendants(node)
    if node = @nodes[node.to_s]
      node.descendants.collect { |d| d.label }
    else
      []
    end
  end

  def parents(node)
    if node = @nodes[node.to_s]
      node.parents.collect { |d| d.label }
    else
      []
    end
  end

  def children(node)
    if node = @nodes[node.to_s]
      node.children.collect { |d| d.label }
    else
      []
    end
  end

protected
  def next_prime
    @last_prime = @prime.next_to(@last_prime)
  end
end
