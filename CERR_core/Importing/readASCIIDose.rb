  #This code parses RTOG dose file and creates separate txt files for zValues and dose.
  #Written by Aditya Apte, 03/24/08
  
  tStart = Time.now.to_f
  doseFileName = ARGV[0]
  puts('Reading ASCII dose file '+doseFileName)
  fzval = File.open('zValueRuby.txt', 'w') 
  fdose = File.open('doseRuby.txt', 'w') 
  #File.open('C:\Projects\CERR support\P0438cP005_aapm\aapm0160', 'r') do |f1|   
  File.open(doseFileName, 'r') do |f1|   
    f1.gets #ignore firest line
	allLines = ''
	while line = f1.gets   
        indZ1 = line.index('"')
	    if indZ1 != nil
	      #z-value
		  line_new = line[indZ1+1..line.length]
		  indZ2 = line_new.index('"')
	      line_new = line_new[indZ2+1..line.length]
		  fzval.puts line_new
	    else
	      #dose
		  #fdose.puts line.dump.gsub('\000','').gsub('"','').gsub('\n','').chomp
		  #Works
		  #a = line.dump.gsub('\000','').gsub('"','').gsub('\n','').chomp.split(",")
		  #a.each {|c| fdose.puts c}
		  #Do not parse
		  fdose.puts line
		  
        end		
    end  	
  end  
  fzval.close
  fdose.close
  
  #puts('Done reading ASCII dose file '+doseFileName)
  deltaT = Time.now.to_f - tStart
  puts("Read dose in " + deltaT.round.to_s + " seconds")
  