require 'tecode/data'

def print_all(s)
  s.page = -1
  puts "Session has #{s.pages} page(s)"
  puts "Page #{s.page}:"
  s.each do |index, row, item|
    puts "[#{s.page}, #{row}](#{index}) = #{item}"
  end
  puts "----"
  while(s.page >= 2) do
    puts "Page #{s.page - 1}:"
    s.each_page_prev do |index, row, item|
      puts "[#{s.page}, #{row}](#{index}) = #{item}"
    end
    puts "----"
  end
end

arr = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
pc = TECode::Data::PagedCollection.new(arr)

puts arr.inspect
print_all(pc.new_session(2))
print_all(pc.new_session(5))
