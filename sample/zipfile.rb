require 'tecode'
require 'tecode/zip'

TECode::ZipFile.open(ARGV.shift, "w") do |zip|
  ARGV.each { |f| zip.add(f) }
end
