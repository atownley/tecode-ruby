require 'tecode/data'

page_size = 2
if ARGV.size > 0
  page = ARGV.shift.to_i
  if ARGV.size > 0
    page_size = ARGV.shift.to_i
  end
else
  page = 1
end

arr = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
pc = TECode::Data::PagedCollection.new(arr)
s = pc.new_session(page_size)
s.go_to(page)

puts arr.inspect
puts "#{s.pages} pages"
s.each do |index, row, item|
  puts "[#{s.page}, #{row}](#{index}) = #{item}"
end
