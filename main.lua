--[[

**Sample code for a Gideros Studio iPhone plugin **

License at the end of main.lua and CBSamplePlugin.mm
If you see any mistakes, misconceptions or possible enhancements, please let
Caroline know on the Gideros Forum

This is not a useful plugin example - it is just for sample reference code.
There is no UIKit functionality.


To set up the plugin:

1. 	Add CBSamplePlugin.mm in Xcode to the GiderosiPhonePlayer project.
2. 	Connect the iPhone and build and run the GiderosiPhonePlayer app on the iPhone
3. 	Load the CBSamplePlugin project into Gideros Studio
4.	In Gideros Studio, under Player Menu > Player Settings, untick Localhost, and enter
	the IP address on your iPhone (wireless connection is needed)
5.	Run the program in Gideros Studio.
6.	You should have both the debug console open in Xcode, and the Output console in Gideros Studio
	Messages from the plugin will be printed in the Xcode console, and messages from Lua will 
	be printed in the Gideros Studio console


Plugin concepts:

The Lua C API relies on a "stack" to communicate between the C plugin and the Lua code

This stack is First in, First off (FIFO)

For example:

Push "fred" onto an empty stack			--stack:	==1 "fred" -1==

Push 1234 onto the stack				--stack:	==2  1234  -2==
													==1 "fred" -1==

Push a table onto the stack				--stack:	==3  table -1==
													==2  1234  -2==
													==1 "fred" -3==

Pop 1 off the stack 					--stack:	==2  1234  -2==
													==1 "fred" -1==

Pop 2 off the stack						--stack:	    empty

In the C API, the stack is referenced by the position in the stack
In the example above, "fred" is at position 1, so whenever the stack is
referenced, "fred" can be accessed at 1. Notice the number on the right hand
side. This is a relative position to the top. When "fred" is at the top of the stack, 
it is in relative position -1. When the stack is largest in the example above,
"fred" is in position -3, meaning that there are two above "fred" in the stack.

In the plugin code, I have generally noted what should be expected on
the stack using the same method as above, with the absolute position on the left
and the relative position on the right.

There is a plugin function called stackdump(lua_State *L), which lists what is currently on
the stack. (Really useful, as keeping track can be very difficult.) This can be called
from the plugin whenever you are uncertain what is on the stack. It can also be
called from Lua CBSamplePlugin.stackdump()

Samples are:

1.	Send two integers to the plugin to be added together and return an integer result

2.	Send a string to the plugin. When the string is received, the plugin dispatches an
	event, which is picked up in Lua

3.	Send a table with keys to an NSDictionary

4.	Send a table array for sorting and return the sorted table array

5.	Create a new table of localised day names in the plugin and return it to Lua

6.	Similar to Sample 3 - create NSDictionaries of personData, 
	this time saving the NSDictionaries in an array in the Objective C helper class.
	Return the array count and a pointer to the array using lightuserdata.
	Get a personData table back from the array using the array pointer.
	
7.	Create a callback function, with variable arguments. This will be a Lua function called
	from the plugin.


Other notes:

When you create a new function to be called from Lua, add that function to 
the registry list in loader(). If you get the message "attempt to call method xxx (a nil value)"
then you have probably forgotten to add the function to the plugin loader()

Plugin functions are always:
static int function_name(lua_State *L) { return noOfParameters }
noOfParameters is the number of parameters held on the stack to return to Lua

lua_State *L holds the stack

]]


--set up the plugin
--In the plugin, REGISTER_PLUGIN sets the Lua external name as "CBSamplePlugin"
--however g_initializePlugin sets the global internal name as "sample"

print("Starting Samples")

require "sample"

--Sample 1 - Send two integers to be added together and return an integer result

--the values 24 and 48 will be placed on the stack for
--the function addTwoIntegers to calculate
--the result will be placed on the stack
--and returned to Lua in "result"

local result = CBSamplePlugin.addTwoIntegers(24, 48)
print("\n\nSample 1 - Result of addTwoIntegers:", result, "\n\n")


--Sample 2 - Send a string to the plugin. When the string is received, the plugin dispatches an
--event, which is picked up in Lua. (Difficulty level - tricky)

--Program flow:
--1. call plugin function stringEvent with a string parameter
--2. stringEvent receives string 
--3. stringEvent calls function CBSamplePlugin->stringEvent to dispatch an event
--4. Lua receives the dispatched event and performs onStringReceived function

--Note that the stack is complex in the dispatchEvent function
--return parameters are listed in a table 
--and received by the the Event function - onStringReceived

--This is called on the event being dispatched by the plugin
function onStringReceived(params, event)
	print("\n\nSample 2 - String received:")

	--stringReturned was created in the dispatchEvent function
	print("\t\tReceived this string:", params.stringReturned)
end

--Add the listener for the event - note that it is "sample", not "CBSamplePlugin", with a : not a .
sample:addEventListener("stringReceived", onStringReceived)

--Call the plugin function
--note that "sample" is being sent as the first parameter this time, because the plugin will
--get the C++ CBSamplePlugin class from "sample", so that the event can be dispatched from there

CBSamplePlugin.stringEvent(sample, "RSVP!")


--Sample 3. Send a table with keys to an NSDictionary

local personData = {["firstName"] = "Johnny", ["lastName"] = "Depp", ["age"] = 48, ["male"] = true }
CBSamplePlugin.tableWithKeys(personData)

print("\n\nSample 3 - table printed on Xcode debug console\n\n")


--Sample 4.	Send a table array for sorting and return the sorted table array

local sortedResult = CBSamplePlugin.sortTable({"giraffe", "antelope", "aardvark", "zebra", "badger"})


print("\n\nSample 4 - sorted Result:")

for i = 1, #sortedResult do
	print("\t\t", sortedResult[i])
end

print("\n\n")


--Sample 5.	Create a new table of localised day names and return a table with keys

local dayNames = CBSamplePlugin.getDayNames()

--the key day3 is set up in the plugin
print("\nSample 5 - Day number 3", dayNames.day3,"\n\n")


--Sample 6.	Similar to Sample 3 - create NSDictionaries of personData, 
--this time saving the NSDictionaries in an array in the Objective C helper class.
--return a pointer to the array using lightuserdata
--Get a personData table back from the array using the array pointer

--send "sample", so that the saveTableWithKeys function can call
--a function in the CBSamplePlugin class, which will call method "addPersonNameToArray:"
--in the Objective C helper class to save the NSDictionary in the NSArray
--"retrieveDataForIndex:" in the helper class will return an NSDictionary

local personArray, personCount = CBSamplePlugin.saveTableWithKeys(sample, personData)

print("\nSample 6 - Address of saved NSArray:\n")
print("\t", personArray)
print("\t\tNo of Persons:", personCount)

--Save more data
personData.firstName = "Julia"
personData.lastName = "Gillard"
personData.age = 50
personData.male = false
CBSamplePlugin.saveTableWithKeys(sample, personData)

personData.firstName = "Justin"
personData.lastName = "Bieber"
personData.age = 17
personData.male = true
CBSamplePlugin.saveTableWithKeys(sample, personData)

personData.firstName = "Cathy"
personData.lastName = "Freeman"
personData.age = 38
personData.male = false
personArray, personCount = CBSamplePlugin.saveTableWithKeys(sample, personData)

print("\t", personArray)
print("\t\tNo of Persons:", personCount)


--get data for index 1
--remember that Objective C arrays start at zero
--the array numbers 0 (Johnny Depp) to 3 (Cathy Freeman)

personData = CBSamplePlugin.retrieveData(sample, 1)


print("\n\t\tRetrieved data:")
for key, value in pairs(personData) do
    print("\t\t", key, value)
end


--Sample 7 - Create a callback function, with variable arguments. 
--This will be a Lua function called from the plugin.

local function printName(name)
	print("\n\t\tFunction called from plugin")
	print("\t\t", "Name:", name)
end

local function eventHappened(event, x, y)
	print("\n\t\tFunction called from plugin")
	print("\t\t", "Event:", event, "X:", x, "Y:", y)
end

print("\nSample 7 - Call functions from plugin:")
CBSamplePlugin.doCallback(printName, "Caroline", 1)
CBSamplePlugin.doCallback(eventHappened, "Touched", 52, 243, 3)

print("\n\nFinish\n")


--[[******************************************************************************
* Copyright (C) 1994-2008 Lua.org, PUC-Rio.  All rights reserved.
* CBSamplePlugin.gproj and CBSamplePlugin.mm are copyright (C) 2011 Caroline Begbie and Gideros.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
******************************************************************************
]]