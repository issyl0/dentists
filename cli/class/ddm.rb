class DentistDataManipulation
	attr_accessor :dbConnection

	# Now initialise the database connection.
	def initialize
		# Define the database connection to the dentist_book.db SQLite database.
		@dbConnection = SQLite3::Database.new( "../db/dentist_book.db" )
	end

	# Now a separate part of the program that is called from the menu when the
	# user selects option 1.
	def add_dentist

		# Tell the user what this part of the program does.
		print "\t\t\tDentist Addition\n"

		# Initialise variables.
		fname = "" # Forename.
		sname = "" # Surname.
		addr = ""  # Address.
		regdate = ""    # Registration date.
		certnum = 0     # Certificate number.
		qualname = ""    # Qualification name.
		qualyear = 0     # Qualification year.
		dqid = 0   # Dentist ID foreign key in the qualifications table value.

		# Now assign them the user's input, stripping the new line from the
		# end.
		print "Certificate Number: "
		certnum = gets.chomp
		print "Surname: "
		sname = gets.chomp
		print "Forename: "
		fname = gets.chomp
		print "Address: "
		addr = gets.chomp
		print "Registration Date (yyyy-mm-dd): "
		regdate = gets.chomp

		# Validation.
		if certnum == 0 then
			print "Enter a certificate number.\n"
		end
		if sname == "" or fname == "" or addr == "" or regdate == "" then
			print "Enter something for all of the values!\n"
			print "Resetting values... please start again...\n"
		# Some redundant lines of code because there are no loops yet to take
		# the user back to the entering section - the program just ends.  :-(
			certnum = ""
			sname = ""
			fname = ""
			addr = ""
			regdate = ""
		else
			print "Woo, you didn't leave any boxes blank.  "
			# There was more validation here that set this value to true, but it
			# didn't work, so it's implicitly set to true if the user hasn't left
			# any boxes blank.  NEEDS FIXING.
			validatesdentyesno = true
		end

		# If the dentist data validates, insert the data into the database and
		# display a message to the user when it has been inserted.  Eventually
		# this will re-display the main menu...
		if validatesdentyesno == true then
			dent_sql = @dbConnection.prepare( "INSERT INTO dentist (forename,surname,address,reg_date,cert_num) VALUES (?,?,?,?,?)" )
			dent_sql.execute(fname,sname,addr,rd,cn)
			dent_last_pk = @dbConnection.execute( "SELECT last_insert_rowid()" )
			puts "Dentist information successfully inserted.\n"
		end


		# Some validation so that the user can say stop when he/she has entered
		# all the qualifications for a particular dentist.  Also, the
		# qualification insertion. 
		puts "Now enter the dentist's qualifications.  Type 'FINISH' when there are no more to add."
		# Until the user types FINISH into the Qualification Name box, carry on looping.
		until qualname == "FINISH"
			puts "Qualification name: "
			qualname = gets.chomp
			if qualname != "FINISH" then
				puts "Qualification year: "
				qualyear = gets.chomp
				qual_sql = @dbConnection.prepare( "INSERT INTO qualification (id,name,year) VALUES (?,?,?)" )
				# Assign the value of the current database primary key (for this
				# insertion) to dqid, to satisfy the foreign key of the qualifications
				# table.
				dqid = dent_last_pk
				qual_sql.execute(dqid,qualname,qualyear)
				puts "Dentist qualification information successfully inserted."
			end
		end

		# Make the method return a blank line, then a value, then end it and
		# loop back to the top.
		puts
		puts "Add another dentist.  If you would not like to, press Ctrl+C on your keyboard now."
		return add_dentist

	# End add_dentist method.	
	end

	def search_dentist
		# Search dentists with some much cleaner code!
		
		# Get the user's choice of ascending or descending order for the searches.
		puts "Ascending or descending order?\n
				1. Ascending.\n
				2. Descending."
		orderby_choice = gets.chomp

		puts "What field would you like to use to search dentists?\n
				1. Surname.\n
				2. Certificate number.\n
				3. Registration date.\n
				4. None, just list all of the dentists.  (Warning: this may take a while and flood your screen with data.)"
		searchby_choice = gets.chomp

		# Only one loop to get the order choice.
		if orderby_choice == "1" then
			order = "ASC"
		else
			order = "DESC"
		end

		# Give the column name to the 'col' variable in order for it just to be
		# added to the SQL string and not clog up every section of the if.
		if searchby_choice.to_i == 1
			puts "Enter a name to search for: "
			col = "surname"
		elsif searchby_choice.to_i == 2
			puts "Enter a certificate number to search for: "
			col = "cert_num"
		elsif searchby_choice.to_i == 3
			puts "Enter a registration date to search for, in the format yyyy-mm-dd: "
			col = "reg_date"
		elsif searchby_choice.to_i == 4
			puts "Searching for everything..."
		else
			puts "User error."
			exit
		end

		# The main body of the SQL command.
		main_sql = "SELECT * FROM dentist"
		# Now if the user has selected one of the correct numbers...
		if searchby_choice != 4 then
			# Get the user's chosen input.
			search = gets.chomp
			# Now make the last bits of the SQL command with all the variables.
			cond_sql = " WHERE " + col + " = " + search + " ORDER BY " + col + " " + order + ""
		else
		  # Just order by ASC or DESC.
		  cond_sql = " ORDER BY surname " + order + ""
		end

		# Add the two SQL statements together to make the full one.
		sql_cmd = main_sql + cond_sql
		# Print it for debugging purposes so we know that it is correct.
		puts sql_cmd

		# Now get all the values from the database, and output them.
		search_sql = @dbConnection.prepare( sql_cmd )
		output = search_sql.execute()
		check_output_search_results(output, search_sql, search)

	end
		
	def check_output_search_results(output, search_sql, searched)

		# This method saves lines of repeating code as it is called during every
		# if and elsif in search_dentist.  This checks that the data is valid, i.e.
		# while there is data left to output, output the data.
		# Must make this prettier.

		puts "Searching..."	
		checkdata = output.next()
		while checkdata != ""
			puts checkdata
			checkdata = output.next()
		end
		puts "... ended!"
	end

	def remove_dentist
		# Remove a specified dentist.
		
		# Certificate number because it is the only totally unique piece of data
		# visible to the user in the book of dentists.  Not that the user will
		# want to delete dentists very often - I hope!
		puts "Enter the certificate number of the dentist you wish to delete:
		Certificate number.\n"
		user_dent_cert_num = gets.chomp

		main_sql = "DELETE FROM dentist"
		cond_sql = " WHERE cert_num = '" + user_dent_cert_num + "'"
		sql_cmd = main_sql + cond_sql
		
		puts sql_cmd
		remove_sql = @dbConnection.prepare( sql_cmd )
		remove_sql.execute()
		puts "Dentist " + user_dent_cert_num + " deleted.  Searching for the certificate number to be sure..."
		search_rm_certnum(user_dent_cert_num)
	end

	def search_rm_certnum(udcn)
		check_certnum_sql = "SELECT * FROM dentist WHERE cert_num = " + udcn + ""
		puts check_certnum_sql
		check_sql = @dbConnection.prepare( check_certnum_sql )
		searchcn = check_sql.execute()

		indb = searchcn.next()
		if indb == nil
			puts "Dentist successfully removed."
		else
			puts "Try the removal again."
		end
	end
end
