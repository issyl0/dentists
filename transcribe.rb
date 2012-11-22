#!/usr/bin/ruby
# Isabell Long <isabell@issyl0.co.uk>, 2012.
# A web-based database system for the digitisation of a book of 1954
# dentists.
# Dentist/Qualification addition.

require 'rubygems'
require 'sanitize'
require 'mysql'
require 'cgi'

cgi = CGI.new
puts "Content-type: text/html\n\n"

connection_info = File.open("/home/isabell/dentist_db.txt", "r")
connection_string = connection_info.read.chomp
connection_info.close
server, dbname, dbuser, dbpass = connection_string.split(':',4)
$db_connection = Mysql.new server, dbuser, dbpass, dbname

def get_last_dentist_certnum()
	last_dent_certnum = $db_connection.query "SELECT certnum FROM dentist WHERE id = (SELECT max(id) FROM dentist)"
	return last_dent_certnum.fetch_row[0].to_i
end

def dentist_form(cgi)
	ldcnum = get_last_dentist_certnum()
  	puts "
	<p>Add a dentist. The last dentist's certificate number was #{ldcnum}.</p>
	<form method='POST' action='transcribe.rb'>
		Firstname:\t<input type='text' name='fname' value='#{cgi['fname']}'></input>
		<br />
		Surname:\t<input type='text' name='sname' value='#{cgi['sname']}'></input>
		<br />
		Address:\t<input type='text' name='address' value='#{cgi['address']}'></input>
		<br />
		Certificate Number:\t<input type='number' name='cert_num' value='#{cgi['cert_num']}'></input>
		<br />
		Registration Date:\t<input type='text' name='reg_date' id='datepicker' value='#{cgi['reg_date']}'></input>
		<br />
		<input type='hidden' name='formtype' value='dentist'></input>
		<br />
		<input class='submit_button' type='submit' value='Submit'></input>
	</form>

	<p>(If you do not want to enter dentists, <a href='index.html'>go home</a>.)</p>"
end

def get_dentist_certnum(dqid)
	dent_cert_num = $db_connection.query "SELECT certnum FROM dentist WHERE id = #{dqid}"
	return dent_cert_num.fetch_row[0].to_i
end

def qualification_form(cgi,dqid)
	dqcnum = get_dentist_certnum(dqid)
	puts "
	<p>Enter #{dqcnum}'s qualification details below.</p>

	<form method='POST' action='transcribe.rb'>
		Qualification Name:\t<input type='text' name='qual_name' value='#{cgi['qual_name']}'></input>
		<br />
		Qualification Year:\t<input type='number' name='qual_year' value='#{cgi['qual_year']}'></input>
		<br />
		<input type='hidden' name='formtype' value='qualification'></input>
		<br />
		<input type='hidden' name='dentistid' value='#{dqid}'></input>
		<br />
		<input class='submit_button' type='submit' value='Submit'></input>
	</form>

	<p>(If you do not want to enter qualifications, <a href='transcribe.rb'>return to the transcription page</a>.)</p>"
end

# Headers/Footers at the top/bottom of code for displaying forms.
puts "
<html>
	<head>
		<title>Transcribe.</title>
		<link href='style.css' rel='stylesheet' type='text/css' />
		<link rel='stylesheet' href='http://code.jquery.com/ui/1.9.1/themes/base/jquery-ui.css' />
		<script src='//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js'></script>
		<script src='//ajax.googleapis.com/ajax/libs/jqueryui/1.9.1/jquery-ui.min.js'></script>
		<script type='text/javascript' src='main.js'></script>
  	</head>
  	<body>
		<div id='transcribe-content'>"

if cgi['formtype'] == "" then
	# Form visited directly, nothing entered in the boxes.
	dentist_form(cgi)
	
elsif cgi['formtype'] == "dentist" then
	# When submit is clicked on the dentist form, do the following...
	Sanitize.clean(cgi['fname'])
	Sanitize.clean(cgi['fname'])
	Sanitize.clean(cgi['address'])
	Sanitize.clean(cgi['cert_num'])
	Sanitize.clean(cgi['reg_date'])	
	if cgi['fname'] == "" or cgi['sname'] == "" or cgi['address'] == "" or cgi['cert_num'].length <= 4 or cgi['reg_date'] == "" then
	# If one or more things have been entered, but incorrectly, error.
		if cgi['fname'] == "" or cgi['sname'] == "" then
			puts "<p class='error'>Fill in the dentist's full name.</p>"
		elsif cgi['address'] == "" then
			puts "<p class='error'>The dentist must have an address.</p>"
		elsif cgi['cert_num'].length <= 4 then
			puts "<p class='error'>Certificate number must be longer than 4 characters.</p>"
		elsif cgi['reg_date'] == "" then
			puts "<p class='error'>Invalid registration date.</p>"
		end
		# Display the form with the originally entered values.
		dentist_form(cgi)
	else
		# Variable binding. Enables the insertion of untrusted data (ex.
		# apostrophes) legitimately (such as in names).
		send_data_dentist = $db_connection.prepare "INSERT INTO dentist(firstname,secondname,address,certnum,regdate) VALUES(?,?,?,?,?)"
		send_data_dentist.execute cgi['fname'], cgi['sname'], cgi['address'], cgi['cert_num'], cgi['reg_date']
		# Get the primary key of the last entered dentist.
		dent_id = $db_connection.query "SELECT last_insert_id()"
		dqid = dent_id.fetch_row[0].to_i
		qualification_form(cgi,dqid)
	end

elsif cgi['formtype'] == "qualification" then
	# When submit is clicked on the qualifications form, do the following...
	Sanitize.clean(cgi['dentistid'])
	Sanitize.clean(cgi['dentqualcertnum'])
	Sanitize.clean(cgi['qual_name'])
	Sanitize.clean(cgi['qual_year'])

	if cgi['qual_name'] == "" or cgi['qual_year'] == nil then
	# If one or more things have been entered, but incorrectly, error.
		if cgi['qual_name'] == "" then
			puts "<p class='error'>Enter a qualification.</p>"
		elsif cgi['qual_year'] == nil then
			puts "<p class='error'>Enter the year in which the qualification was taken.</p>"
		end
		# Display the form with originally entered values.
		qualification_form(cgi,cgi['dentistid'])
	else
		send_data_qualification = $db_connection.prepare "INSERT INTO qualification(dentistid,qualname,qualyear) VALUES(?,?,?)"
		send_data_qualification.execute cgi['dentistid'], cgi['qual_name'], cgi['qual_year']
		dqid = cgi['dentistid']
		# As there are no errors, clear the box data out.
		cgi.params.delete('qual_name')
		cgi.params.delete('qual_year')
		# Loop as > 1 qualification can be added for each dentist.
		qualification_form(cgi,dqid)
	end
	
else
	puts "Something went wrong."
end

puts "
	</div>
  </body>
</html>"