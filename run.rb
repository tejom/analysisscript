#!/usr/bin/ruby
require 'csv'

FILE_NAME = "./res5.csv"
AUD_RATE = 0.759
POUND_RATE  = 1.3
CAD_RATE = 0.77
KR_RATE = 0.116852
EURO_RATE = 1.11526

numbers = []

def clean_num(n)

	n.gsub!(/[$,]/,"")
	n.gsub!(/year|yr/i,"")
	n.gsub!(/~/,"")
	if n =~ /aud/i
		n.gsub!(/aud/i,"")
		amount = n.match /\d+[.]?\d/
		n.gsub!(amount[0], (amount[0].to_i * AUD_RATE).to_s)
	end
	if n =~ /sek/i
		n.gsub!(/sek/i,"")
		amount = n.match /\d+[.]?\d/
		n.gsub!(amount[0], (amount[0].to_i * KR_RATE).to_s)
	end
	if n =~ /kr/i
		n.gsub!(/kr/i,"")
		amount = n.match /\d+[.]?\d/
		n.gsub!(amount[0], (amount[0].to_i * KR_RATE).to_s)
	end
	if n =~ /GBP/i || n =~ /£/
		n.gsub!("£","")
		amount = n.match /\d+[.]?\d/
		n.gsub!(amount[0], (amount[0].to_i * POUND_RATE).to_s)
	end
	if n =~ /cad/i
		n.gsub!(/cad/i,"")
		amount = n.match /\d+[.]?\d/
		n.gsub!(amount[0], (amount[0].to_i * CAD_RATE).to_s)
	end
	if n =~ /eur|€/i
		n.gsub!(/eur|€/i,"")
		amount = n.match /\d+[.]?\d/
		n.gsub!(amount[0], (amount[0].to_i * EURO_RATE).to_s)
	end
	if n =~ /(hour)|(hr)/
		n = n[/^\S+\b/].to_i * 40 *52
		return n # this is an int
	else
		n = n[/^\S+\b/]
	end
	if n =~ /k/i 
		with_k = n.gsub(/k/i,"").to_i
		if with_k < 10000
			return with_k * 1000 #this is an int 
		end
		return with_k #most likely the k wasnt important
	end
	return n.to_i
end

total = 0
count =0

total_exp =0
count_exp =0

CSV.foreach(FILE_NAME) do |row|

	if (row[2] != "Salary" && !row[2].nil?)  
		num =clean_num row[2]
		if num > 10000 #ignore errors, to small
			total += num
			row_exp = row[5]
			exp= !row_exp.nil? ? row_exp[/^\d+/].to_i : -1
			total_exp += exp if exp >=1
			count_exp += 1 if exp >=1
			numbers << {:sal => num , :location => row[4], :exp => exp, :title => row[1], :desc => row[6]}
			count += 1
		end
	end
end



sort_info = numbers.sort_by { |h| h[:sal] }
puts "top salaries"
sort_info[-10..-1].each {|r|
puts "|#{r[:sal]} | #{r[:title]} | #{r[:exp]} | #{r[:location]} |"
}

exp_array = []
(0..50).to_a.each { |n| exp_array[n] = {:exp => n, :count =>0,:total =>0, :avg =>0, :per =>0}} 
numbers.each { |r| 
	if r[:exp] > -1
		t = exp_array[r[:exp]] 
		t[:count] +=1 #total count for r[:exp]
		t[:total] += r[:sal] #sum of slaries
		t[:avg] = t[:total]/t[:count] #average salary for exp
		t[:per] = (t[:count].to_f/count.to_f * 100).round 2 #percentage exo makes up of responses
		exp_array[r[:exp]] = t
	end
}


puts "Counted: #{count}"
puts "Average: #{total/count}"

puts "Experiece Counted: #{count_exp}"
puts "Experience Average: #{total_exp/count_exp}"


puts "sort experience by size/percentage"
exp_array.sort_by {|r| r[:per]}.each { |r|
puts "| #{r[:exp]} | %#{r[:per]} | #{r[:count]}"
}
puts "sort experience by average salary"
exp_array.sort_by {|r| r[:avg]}.each{ |r|
	puts "| #{r[:exp]} | #{r[:avg]}| #{r[:count]}"
}

linux = 0
windows = 0
numbers.each { |r| 
	linux += 1 if /linux/i.match r[:desc]
	windows += 1 if /window/i.match r[:desc]
}

puts "linux: #{linux}"
puts "windows: #{windows}"

eng =0
eng_total =0
admin =0
admin_total =0
numbers.each { |r| 
	if /engineer/i.match r[:title]
		if ! /manage|dir/i.match r[:title]
			eng += 1 
			eng_total += r[:sal]
		end
	end
	if /admin/i.match r[:title]
		if !/manage|dir/i.match r[:title]
			admin += 1
			admin_total += r[:sal]
		end
	end
}
puts "engineer vs admin"
puts eng
puts admin
puts eng_total/eng 
puts admin_total/admin

sf =0
sf_total =0
london=0
london_total = 0
numbers.each { |r| 
	if (/sf\b|san f|bay a|silicon val/i.match(r[:location] )&& !r[:location].include?("Not") )
		#thanks "Not Bay area guy..."
		sf +=1
		sf_total += r[:sal]
	end
	# if /london|uk|united kingdom|england/i.match r[:location]
	if /london/i.match r[:location]
		london += 1
		london_total += r[:sal]
	end
}
puts "sf vs london"
puts sf 
puts london
puts sf_total/sf 
puts london_total/london

BUCKETS = 23
hist_array = Array.new(BUCKETS+2,0)
min_sal = 10000
max_sal = sort_info.last[:sal]
puts max_sal
interval = (max_sal - min_sal) / BUCKETS
puts interval
numbers.each { |r| 
	b = r[:sal]/interval
	hist_array[b] += 1
}

hist_array.each_index { |i| 
 puts "#{i*interval}:\t[#{ 'x' * hist_array[i]}" }

engineer_person =0 
engineer_person_total = 0
manager_person =0 
manager_person_total = 0
numbers.each { |r| 
	if /manager|dir/i.match r[:title]
		manager_person += 1
		manager_person_total += r[:sal]
	end
}

puts "manager Average: #{manager_person_total/manager_person} #{manager_person}"
puts "engineer avergage : #{eng_total/eng}"
puts "employee avergage : #{(eng_total+admin_total)/(eng+admin)}"

puts "responses for years of experience for senior titles"
senior_exp_array = []
(0..50).to_a.each { |n| senior_exp_array[n] = {:exp => n, :count =>0} }
numbers.each { |r| 
	if /sr|senior/i.match r[:title]
		if r[:exp] > -1
			senior_exp_array[r[:exp]][:count] += 1
		end
	end
}
puts senior_exp_array.select {|r| r[:count] > 0}.sort_by { |r| r[:count] }

 ##sf bay
 sf = numbers.select{|r| /sf\b|san f|bay a|silicon val/i.match(r[:location] )&& !r[:location].include?("Not")}
 puts sf
 sf_exp = 0
 sf.each { |r| 
 	sf_exp += r[:exp]
 }

 puts "bay area experience avaerge #{sf_exp/sf.size}"
