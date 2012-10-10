require 'rubygems'
require 'sqlite3'

# Display the main menu.
puts "1. Add a dentist."
puts "2. List the dentists."
puts "3. Remove a dentist."
puts "4. Quit."

# Pull in the DentistDataManipulation class.
require './class/ddm'
dentists = DentistDataManipulation.new

# Validate the user's menu choice by getting the input string and stripping
# the new line from the end.
menu_choice = gets.chomp.to_i
if menu_choice == 1 then
	dentists.add_dentist
elsif menu_choice == 2 then
	dentists.search_dentist
elsif menu_choice == 3 then
	dentists.remove_dentist
elsif menu_choice == 4 then
	exit
else
	puts "Select a number from 1 to 4."
end
