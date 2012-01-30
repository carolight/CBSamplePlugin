#include "gideros.h"
#include "lua.h"
#include "lauxlib.h"

static const char KEY_OBJECTS = ' ';

static const char* STRING_RECEIVED = "stringReceived";

//The class CBSamplePluginHelper is set as a private variable "helper"
//in the C++ class CBSamplePlugin
//Functions in CBSamplePlugin can then call any Objective C method
//in the helper class

#pragma mark CBSamplePluginHelper - Objective C Class

@interface CBSamplePluginHelper : NSObject 

@property (nonatomic, retain) NSMutableArray *personNamesArray;

-(void)addPersonNameToArray:(NSDictionary *)personName;
-(NSDictionary *)retrieveDataForIndex:(int)index;

@end

@implementation CBSamplePluginHelper

@synthesize personNamesArray;

-(id)init
{
    if ((self = [super init])) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        self.personNamesArray = array;
        [array release];
    }
    return self;
}

-(void)dealloc
{
    [personNamesArray release];
    [super dealloc];
}

#pragma mark Sample 6 - save data into an NSArray (part 3)

-(void)addPersonNameToArray:(NSDictionary *)personName
{
    NSLog(@"Adding person name to array: %@ %@", 
                            [personName objectForKey:@"firstName"], 
                            [personName objectForKey:@"lastName"]);
    
    [self.personNamesArray addObject:personName];
}

-(NSDictionary *)retrieveDataForIndex:(int)index
{
    NSLog(@"retrieveDataForIndex: %d", index);
    
    NSDictionary *dictionary = nil;
    if (index < personNamesArray.count) {
        dictionary = [self.personNamesArray objectAtIndex:index];
    }
    return dictionary;
}

@end

static int stackdump(lua_State* l);

#pragma mark CBSamplePlugin - C++ class

class CBSamplePlugin : public GEventDispatcherProxy
{
public:
	CBSamplePlugin(lua_State* L) : L(L)
	{
		helper = [[CBSamplePluginHelper alloc] init];
	}
	
	CBSamplePlugin()
	{
		[helper release];
	}
    
#pragma mark Sample 2 - receive a string and dispatch an event (part 2)
	
	void dispatchEvent(const char* type,
					   NSError* error, 
					   NSString *returnMessage)
	{
        NSLog(@"Dispatching event now!");
        
        //==1 plugin details -1==
        
		lua_pushlightuserdata(L, (void *)&KEY_OBJECTS);
		lua_rawget(L, LUA_REGISTRYINDEX);
		
		lua_rawgeti(L, -1, 1);
        
        //==3 Registry table -1==
        //==2 Key Objects table -2==
        //==1 plugin details -3==

		if (!lua_isnil(L, -1))
		{
            //get the function name from the Registry
            //for dispatchEvent
			lua_getfield(L, -1, "dispatchEvent");

            //==4 function for dispatchEvent -1==
            //==3 Registry table -2==
            //==2 Key Objects table -3==
            //==1 plugin details -4==

            //copy the Registry table to the top of the stack
			lua_pushvalue(L, -2);

            //==5 Registry table -1==
            //==4 function for dispatchEvent -2==
            //==3 Registry table -3==
            //==2 Key Objects table -4==
            //==1 plugin details -5==
            
            //get the event strings for "Event"
            //these were set up in loader()
            //"Event" currently only contains STRING_RECEIVED
			lua_getglobal(L, "Event");

            //==6 Event table -1==
            //==5 Registry table -2==
            //==4 function for dispatchEvent -3==
            //==3 Registry table -4==
            //==2 Key Objects table -5==
            //==1 plugin details -6==

            //get the Event function associated with the string "new"
			lua_getfield(L, -1, "new");
            
            //==7 function -1==
            //etc
            
            //remove the Event table
            lua_remove(L, -2);

            //==6 function -1==
            //==5 Registry table -2==
            //==4 function for dispatchEvent -3==
            //==3 Registry table -4==
            //==2 Key Objects table -5==
            //==1 plugin details -6==
            
            //push the event type ("stringReceived" in this sample)
			lua_pushstring(L, type);

            //==7 "stringReceived" -1==
            //==6 function -2==
            //==5 Registry table -3==
            //==4 function for dispatchEvent -4==
            //==3 Registry table -5==
            //==2 Key Objects table -6==
            //==1 plugin details -7==

            //call the "new" event function
            //with "stringReceived" as the parameter
            //One return value is placed on the stack
			lua_call(L, 1, 1);

            //==6 table returned from "new" -1==
            //==5 Registry table -2==
            //==4 function for dispatchEvent -3==
            //==3 Registry table -4==
            //==2 Key Objects table -5==
            //==1 plugin details -6==
			
			if (error)
			{
				lua_pushinteger(L, error.code);
				lua_setfield(L, -2, "errorCode");
				
				lua_pushstring(L, [error.localizedDescription UTF8String]);
				lua_setfield(L, -2, "errorDescription");			
			}
			
			if (returnMessage)
			{
                //any parameters are pushed into the table
                //returned from "new"
                //this table will be sent to the Lua Event function
                lua_pushstring(L, [returnMessage UTF8String]);
                lua_setfield(L, -2, "stringReturned");
			}
			
            //two tables are sent to the 
            //dispatch event function
			if (lua_pcall(L, 2, 0, 0) != 0)
			{
				g_error(L, lua_tostring(L, -1));
				return;
			}
		}
		lua_pop(L, 2);
	}
    
    void stringEvent(lua_State *L)
    {
        //==2 "RSVP!" -1==
        //==1 plugin details -2==

        //get the string from the top of the stack
        const char* stackstring = luaL_checkstring(L, -1);
        
        //convert to an NSString
        //not necessary, but it shows you how to do it
        NSString *string = [NSString stringWithUTF8String:stackstring];
        NSLog(@"String received: %@", string);
        
        //pop the string off the stack - no longer needed
        lua_pop(L, 1);
        
        //==1 plugin details -1==
        
        NSError *error = nil;
        
        NSString *returnMessage = @"Message Received!";
        dispatchEvent(STRING_RECEIVED, error, returnMessage);
    }
    
#pragma mark Sample 6 - save data into an NSArray (part 2)

    void saveTableWithKeys(lua_State *L)
    {
        
        //==2 personData table -1==
        //==1 plugin details -2==
        
        /*
         to iterate through a table on the stack,
         lua_pushnil(L)
         while (lua_next(L, 1) != 0 {  //1 is the position on the stack of the table to be iterated
         //lua_next will put the key then the value on the stack
         do stuff
         lua_pop(L, 1); //pop the value off the stack, retaining the key for the next iteration
         }
         */
        
        lua_pushnil(L);
        
        //==3 nil -1==
        //==2 personData table -2==
        //==1 plugin details -3==
        
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        
        while (lua_next(L, 2) != 0) {
            //==4 value - table value -1==
            //==3 key - key -2==
            //==2 personData table -3==
            //==1 plugin details -4==
            
            //check what type of value it is
            id finalValue = nil;
            switch (lua_type(L, -1)) {
                case LUA_TNUMBER: {
                    int value = lua_tonumber(L, -1);
                    NSNumber *number = [NSNumber numberWithInt:value];
                    finalValue = number;
                    break;
                }
                case LUA_TBOOLEAN: {
                    int value = lua_toboolean(L, -1);
                    NSNumber *number = [NSNumber numberWithBool:value];
                    finalValue = number;
                    break;
                }
                case LUA_TSTRING: {
                    NSString *value = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
                    finalValue = value;
                    break;
                }
            }
            
            //save into an NSDictionary
            NSString *key = [NSString stringWithUTF8String:luaL_checkstring(L, -2)];
            [dictionary setObject:finalValue forKey:key];
            
            // removes 'value'; keeps 'key' for next iteration
            lua_pop(L, 1);
            
        }
        
        [helper addPersonNameToArray:dictionary];
        
        //Add the address of the Array to the stack
        //using lightuserdata
        lua_pushlightuserdata(L, helper.personNamesArray);
        
        //push the array count
        lua_pushnumber(L, helper.personNamesArray.count);
    }

    void retrieveData(lua_State *L)
    {
        //==2 index to retrieve -1==
        //==1 plugin data -2==
        
        stackdump(L);

        int index = lua_tointeger(L, -1);
        NSDictionary *dictionary = [helper retrieveDataForIndex:index];
        
        lua_pop(L, 1);
        //Create a new table
        lua_newtable(L);
        
        //==2 newtable -1==
        //==1 plugin data -2==
        

        lua_pushstring(L, [[dictionary objectForKey:@"firstName"] UTF8String]);
        
        //==3 "Julia" -1==
        //==2 newtable -2==
        //==1 plugin data -3==
        
        lua_setfield(L, 2, "firstName");

        //==2 newtable -1==
        //==1 plugin data -2==
        
        lua_pushstring(L, [[dictionary objectForKey:@"lastName"] UTF8String]);
        lua_setfield(L, 2, "lastName");
        
        lua_pushinteger(L, [[dictionary objectForKey:@"age"] intValue]);
        lua_setfield(L, 2, "age");
        
        lua_pushboolean(L, [[dictionary objectForKey:@"male"] boolValue]);
        lua_setfield(L, 2, "male");
    }

private:
	lua_State* L;
    CBSamplePluginHelper* helper;
};

#pragma mark end of C++ CBSamplePlugin class

static int destruct(lua_State* L)
{
	void* ptr = *(void**)lua_touserdata(L, 1);
	GReferenced* object = static_cast<GReferenced*>(ptr);
	CBSamplePlugin* sample = static_cast<CBSamplePlugin*>(object->proxy());
	
	sample->unref();
	
	return 0;
}

static CBSamplePlugin* getInstance(lua_State* L, int index)
{
	GReferenced* object = static_cast<GReferenced*>(g_getInstance(L, "CBSamplePlugin", index));
	CBSamplePlugin* sample = static_cast<CBSamplePlugin*>(object->proxy());
    
	return sample;
}

#pragma mark Sample 1 - Add Two Integers

static int addTwoIntegers(lua_State *L)
{
    //==2 firstInteger -1==
    //==1 secondInteger -2==
    
    NSLog(@"Sample 1 - addTwoIntegers");
    
    //list the stack in the Xcode debug console
    stackdump(L);
    
    //this will take the top item off the stack, ie in position -1 and place the
    //value in firstInteger
    int firstInteger = lua_tointeger(L, -1);
    //this will take the second item off the stack, ie in position -2 and place the
    //value in secondInteger
    int secondInteger = lua_tointeger(L, -2);
    
    //the stack itself is unchanged
    
    //add the two integers together
    int result = firstInteger + secondInteger;

    //place the result on the stack
    lua_pushinteger(L, result);
    
    //==3 result -1==
    //==2 firstInteger -1==
    //==1 secondInteger -2==
    
    //print a separator in the debug console
    NSLog(@"**************\n\n");

    //one item off the top of the stack, the result, is returned
    return 1;
}

#pragma mark Sample 2 - Receive a string (part 1)

static int stringEvent(lua_State *L)
{
    //==2 "RSVP!" -1==
    //==1 plugin details -2==
    
    NSLog(@"Sample 2 - stringEvent");
    stackdump(L);
    
    CBSamplePlugin *sample = getInstance(L, 1);
    
    //further action is taken in the CBSamplePlugin class
    sample->stringEvent(L);

    //print a separator in the debug console
    NSLog(@"**************\n\n");
    
    //don't return anything
    return 0;
}

#pragma mark Sample 3 - Receive a table with keys

static int tableWithKeys(lua_State *L)
{
    NSLog(@"Sample 3 - tableWithKeys");
    
    //==1 table -1==
    
    /*
     to iterate through a table on the stack,
     lua_pushnil(L)
     while (lua_next(L, 1) != 0 {  //1 is the position on the stack of the table to be iterated
     //lua_next will put the key then the value on the stack
     do stuff
     lua_pop(L, 1); //pop the value off the stack, retaining the key for the next iteration
     }
     */

    lua_pushnil(L);
    
    //==2 nil -1==
    //==1 tableWithKeys -1==

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    while (lua_next(L, 1) != 0) {
        
        //==3 value - table value
        //==2 key - key
        //==1 tableWithKeys -1==


        //check what type of value it is
        id finalValue = nil;
        switch (lua_type(L, -1)) {
            case LUA_TNUMBER: {
                int value = lua_tonumber(L, -1);
                NSNumber *number = [NSNumber numberWithInt:value];
                finalValue = number;
                break;
            }
            case LUA_TBOOLEAN: {
                int value = lua_toboolean(L, -1);
                NSNumber *number = [NSNumber numberWithBool:value];
                finalValue = number;
                break;
            }
            case LUA_TSTRING: {
                NSString *value = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
                finalValue = value;
                break;
            }
        }
        
        //save into an NSDictionary
        NSString *key = [NSString stringWithUTF8String:luaL_checkstring(L, -2)];
        [dictionary setObject:finalValue forKey:key];

        // removes 'value'; keeps 'key' for next iteration
        lua_pop(L, 1);
        
    }
    
    NSLog(@"\n\nSample 3:\nNSDictionary: %@", dictionary);
    
    //print a separator in the debug console
    NSLog(@"**************\n\n");
    
    //no return parameters
    return 0;
}

#pragma mark Sample 4 - Sort a table of strings

static int sortTable(lua_State *L)
{
    NSLog(@"Sample 4 - sortTable");
    //==1 tableToBeSorted -1==
    
    //push nil onto the stack so that the while loop will work
    lua_pushnil(L);
    
    //==2 nil -1==
    //==1 tableToBeSorted -2==
    
    //move the table into an NSMutableArray
    NSMutableArray *array = [NSMutableArray array];
    
    while (lua_next(L, 1) != 0) {
        
        //==3 value - sort this -1==
        //==2 key - key -2==
        //==1 tableToBeSorted -3==
        
        NSString *value = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
        [array addObject:value];

        //removes 'value'; keeps 'key' for next iteration
        lua_pop(L, 1);
    }

    //pop the table off the stack, as we don't need it any more
    lua_pop(L, 1);
    
    [array sortUsingSelector:@selector(compare:)];
    
    NSLog(@"\n\nSample 4:\nSorted array: %@", array);

    //Create a new table
    lua_newtable(L);
    
    //==1 newtable -1==
    
    //Lua tables start from 1, whereas C arrays start from 0
    int index = 1;
    for (NSString *string in array) {
        
        //push the table index
        lua_pushnumber(L, index++);
        //push the string on the stack, converting it to a const char*
        lua_pushstring(L, [string UTF8String]);

        //==3 "animal string" -1==
        //==2 index           -2==
        //==1 newtable        -3==
        
        //store index and string value into the table
        lua_rawset(L, -3);      /* Stores the pair in the table */

        //==1 newtable        -1==
        
        
        //Note - if you are using keys instead of indexes, use lua_setfield():
        //push the string on the stack, converting it to a const char*
        //lua_pushstring(L, [string UTF8String]);
        //lua_setfield(L, -3, "keyname");
    }

    //print a separator in the debug console
    NSLog(@"**************\n\n");
    
    return 1;
}

#pragma mark Sample 5 - Return a table of localized day names

static int getDayNames(lua_State *L)
{

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSArray *dayNames = [dateFormatter weekdaySymbols];
    [dateFormatter release];
    
    NSLog(@"Sample 5 - dayNames: %@", dayNames);

    //Create a new table
    lua_newtable(L);
    
    //==1 newtable -1==

    int dayNumber = 1;
    for (NSString *day in dayNames) {
        //push the day name onto the stack
        lua_pushstring(L, [day UTF8String]);
        
        //==2 "eg Sunday" -1==
        //==1 newtable -2==
        
        //set up the key for the day number
        NSString *key = [NSString stringWithFormat:@"day%d", dayNumber++];
        
        //add the day name to the table
        lua_setfield(L, -2, [key UTF8String]);
        
        //lua_setfield pops the value off the stack
        //==1 newtable -1==
    }
    
    //print a separator in the debug console
    NSLog(@"**************\n\n");
    
    return 1;
}

#pragma mark Sample 6 - save data into an NSArray (part 1)

static int saveTableWithKeys(lua_State *L)
{
    NSLog(@"Sample 6 - save data into an NSArray");
    
    CBSamplePlugin *sample = getInstance(L, 1);
    
    //further action is taken in the CBSamplePlugin class
    sample->saveTableWithKeys(L);

    //== 4 array count -1==
    //== 3 array address -2==
    //== 2 personData table -3==
    //== 1 plugin details -4==
    
    //return the array count and the array address
    return 2;
}

static int retrieveData(lua_State *L)
{
    CBSamplePlugin *sample = getInstance(L, 1);
    sample->retrieveData(L);
    
    //==2 newtable with person data -1==
    //==1 plugin data -2==
    
    //print a separator in the debug console
    NSLog(@"**************\n\n");
    
    //return table
    return 1;
}

#pragma mark Sample 7 - call a Lua function from C

static int doCallback(lua_State *L)
{
    NSLog(@"doCallback");
    
    
    //==4 no of parameters -1==
    //==3 param -2==
    //==2 param -3==
    //==1 function -4==
    
    stackdump(L);
    
    int noOfParameters = lua_tointeger(L, -1);
    
    //remove no of parameters off the stack
    lua_pop(L, 1);
    
    //call the function
    //parameters are top of the stack
    //function name is known because it is in the stack
    //position after noOfParameters
    //0 here is the number of expected returns 
    //from the function, which will be on the stack
    lua_call(L, noOfParameters, 0);
    
    //print a separator in the debug console
    NSLog(@"**************\n\n");
    
    return 0;
}

#pragma mark stackdump()

static int stackdump(lua_State* l)
{
    NSLog(@"stackdump");
    
    int i;
    int top = lua_gettop(l);
    
    printf("total in stack: %d\n",top);
    
    for (i = 1; i <= top; i++)
    {  //repeat for each item in the stack
        printf("  ");  
        int t = lua_type(l, i);
        switch (t) {
            case LUA_TSTRING:  //strings
                printf("string: '%s'\n", lua_tostring(l, i));
                break;
            case LUA_TBOOLEAN:  //booleans
                printf("boolean %s\n",lua_toboolean(l, i) ? "true" : "false");
                break;
            case LUA_TNUMBER:  //numbers
                printf("number: %g\n", lua_tonumber(l, i));
                break;
            default:  //other values
                printf("%s\n", lua_typename(l, t));
                break;
        }
    }
    printf("\n"); 
    return 0;
}

#pragma mark Initialization

static int loader(lua_State *L)
{
    //This is a list of functions that can be called from Lua
	const luaL_Reg functionlist[] = {
        {"addTwoIntegers", addTwoIntegers},
        {"stringEvent", stringEvent},
        {"tableWithKeys", tableWithKeys},
        {"sortTable", sortTable},
        {"getDayNames", getDayNames},
        {"saveTableWithKeys", saveTableWithKeys},
        {"retrieveData", retrieveData},
        {"stackdump", stackdump},
        {"doCallback", doCallback},
		{NULL, NULL},
	};
	
	g_createClass(L, "CBSamplePlugin", "EventDispatcher", NULL, destruct, functionlist);
	
    //load up events into the plugin table
    //==1 plugin table -1==
    
	lua_getglobal(L, "Event");
	lua_pushstring(L, STRING_RECEIVED);
    
    //==2 "stringReceived" -1==
    //==1 plugin table -2==
    
	lua_setfield(L, -2, "STRING_RECEIVED");
	lua_pop(L, 1);
    
    //==1 plugin table -1==

    
	// create a weak table in LUA_REGISTRYINDEX that can be accessed with the address of KEY_OBJECTS
	lua_pushlightuserdata(L, (void *)&KEY_OBJECTS);
	lua_newtable(L);                  // create a table
	lua_pushliteral(L, "v");
	lua_setfield(L, -2, "__mode");    // set as weak-value table
	lua_pushvalue(L, -1);             // duplicate table
	lua_setmetatable(L, -2);          // set itself as metatable
	lua_rawset(L, LUA_REGISTRYINDEX);	
	
    //reference to the C++ class which will have a pointer to Objective C classes
	CBSamplePlugin* sample = new CBSamplePlugin(L);
	g_pushInstance(L, "CBSamplePlugin", sample->object());
    
	lua_pushlightuserdata(L, (void *)&KEY_OBJECTS);
	lua_rawget(L, LUA_REGISTRYINDEX);
	lua_pushvalue(L, -2);
	lua_rawseti(L, -2, 1);
	lua_pop(L, 1);	
    
	lua_pushvalue(L, -1);
	lua_setglobal(L, "sample");

	//return the pointer to the plugin
	return 1;
}

static void g_initializePlugin(lua_State* L)
{
	lua_getglobal(L, "package");
	lua_getfield(L, -1, "preload");
	
	lua_pushcfunction(L, loader);
	lua_setfield(L, -2, "sample");
	
	lua_pop(L, 2);	
}

static void g_deinitializePlugin(lua_State *L)
{
    
}

REGISTER_PLUGIN("CBSamplePlugin", "1.0")


/******************************************************************************
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
    ******************************************************************************/
