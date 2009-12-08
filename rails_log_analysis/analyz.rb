#!/usr/bin/ruby

require 'date'

class String
  def blank?
    self.length == 0
  end
end

print "Requests from which IP? [ip or nothing] "
ip = $stdin.gets.chomp
print "Consider requests going back to [date or nothing] "
date_str = $stdin.gets.chomp
date = date_str.length == 0 ? nil : Date.parse(date_str)
print "Show errors only? [y/n] "
show_errors_only = $stdin.gets.chomp == 'y'
print "Type of error to look for [class or nothing] "
error_type = $stdin.gets.chomp
print "Type of error to ignore [class or nothing] "
ignore_error_type = $stdin.gets.chomp
print "Request to look for [class#[optional action] or nothing] "
request = $stdin.gets.chomp

file = File.open(ARGV[0], 'r')

while (line = file.gets) do
  if line.index("Processing ") == 0
    line =~ /^Processing (.*?) \(for (.*?) at (.*?) (\d+):(\d+):(\d+)\)/
    if !date.nil? and Date.parse($3) < date
      next
    end
    if ip.length > 0 and $2 != ip
      next
    end
    if request.length > 0 and $1 =~ /^#{Regexp.quote(request)}/
      next
    end

    body = line

    body_line = nil
    body << body_line while (body_line = file.gets) && !body_line.index("Processing")
    line = body_line

    
    body.rstrip!

    next if show_errors_only && body !~ /ActionController::UnknownAction/m #body =~ /\(500 Internal Error|\)$/m or body =~ /\(404 Page Not Found\)$/m

    if (error_type.blank? && ignore_error_type.blank?) || (!error_type.blank? && body.include?(error_type)) ||
     (!ignore_error_type.blank? && !body.include?(ignore_error_type))
      puts body
      puts "\n==============================================================================================================================================\n\n"
    end

    body_line ? redo : break
  end
end
