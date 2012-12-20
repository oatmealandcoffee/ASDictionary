ASDictionary
============

**A pure Applescript dictionary class to pick up where the record class left off**

About
=====

The `record` class in Applescript is, at its core, a dictionary—a key-value pairing of data—but with strict limitations:

* Keys are hard-coded, requiring the script to know all the keys before runtime.
* Records are not dynamic except for changing values for keys. There is no way to add or remove key-value pairs.
* There is no way to iterate through keys or values. Functions like length and count give the number of records, but then there is no ability to call values by index.

`OCDictionary` addresses most of this with a simple-to-use, yet entirely Applescript-native code. There is no need to take on the weight of an ApplescriptObjC application with Xcode's bare bones debugging tools to gain access to `NSDictionary` and `NSMutableDictionary` classes, and instead keep working with more developer-friendly tools like Script Debugger.

**Possible future plans**

Right now, the accessor methods only go by the key and not the value, but that can easily be added. I would like to see more of the functionality that I get in REALbasic and Cocoa's NSDictionary class.
In general, I would like to align functionality with mutable dictionary classes like I see in Cocoa and REALbasic, but the short list includes the following:

* Access values by index
* Remove key-value pairs, in part or all
* string value/description for text output
* seperate keys and values to seperate lists to speed up the `getKeys()` subroutine
* Better error reporting. Right now, it only uses missing value, but that isn't very informative as a few things can go wrong. I had errors in the previous iteration but they weren't handled very well.
* Hash table management could use a bit of optimizing, but it is fast (for Applescript) and it works.

Documentation
=============

**Introduction**

Essentially, the class is a wrapper for a private list of `records` with the format `{key:data, value:data}`. When a key value pair is created, the pair is placed at the end of a `list` and the index recorded in the hash table by the key. Retrieving values is nothing more than seeing if each character has a place in the hash table, getting the index on the last character, and returning the value for that pair. When in doubt about anything, the dictionary returns *`missing value`*.

**Caveats**

*Script Objects and memory*

This uses the `Script Object` features of Applescript, which allows custom OOP in Applescript complete with inheritance. The caveat is that doing this can be very resource and memory intensive.

If you are not familiar with `Script Objects`, then I highly suggest you read the Applescript Language Guide. Suffice to say, however, that all of the action, the class in of itself, is held within the `script OCDictionary...end script` block within the `MakeDictionary()` subroutine.

*Unicode Key Support*

Applescript's text class supports Unicode, moving from ASCII a while ago. Unicode is much broader in scope over ASCII, but `OCDictionary` still checks to be sure that keys are built using an ASCII-centric character set. The currently supported characters include Unicode value 48 (`'0'`) contiguously through 122 (`'z'`) shown in order here:

    0123456789:'<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz
    
This limitation is based on `OCDictionary's` current iteration requiring each node in the hash table hold an array aligned with the numerical value of each character regardless if the array is populated. Supporting the full Unicode set would consume far too much memory even for the shallowest of tables, so sticking with characters 48 through 122 maintains a manageable but still useful character set.

*Convenience Methods*

Script objects cannot instantiate themselves as in Cocoa, a single function is provided to kick things off, but convenience methods are trivial to create:

```
on MakeDictionaryWithValuesAndKeys(someValues, someKeys) -- (list, list) as OCDictionary
  set newDictionary to MakeDictionary() of me
	tell newDictionary
		set valuesAdded to addValuesForKeys(someValues, someKeys)
	end tell
	return newDictionary
end MakeDictionaryWithValuesAndKeys

-- simply call with:
-- set newDictionary to MakeDictionaryWithValuesAndKeys({"ack", "greeble", "ponies"}, {"ACK", "GREEBLE", "PONIES"}) of me
```

**`run{}`**

This subroutine offers examples of syntax and functionality. This combined with the MakeDictionary() subroutine makes for a fully working script.

**`MakeDictionary() -- as OCDictionary`**

If Script Objects are to be used, they need to be declared and returned, and that is all this subroutine does. This contains the entire OCDictionary declaration, so just copy and paste into your script and call with the simple
set testDictionary to MakeDictionary() of me

**`hasKey(aKey) -- (object) as boolean`**

Simple function that will return whether a key exists or not.

**`toggleDataIntegrityChecks() -- as boolean`**

This toggles the data integrity checks. Data integrity is checked on keys and values being sent to the class. That check is very simple—only checking for null or empty list values—so it's very fast, but when compiled over time, it can add up.

**`getKeys() -- as list`**

Returns a list of all the keys found in all the records. If there are no records, it will return an empty list.

**`setValueForKey(aValue, aKey) -- (object, object) as boolean`**

False can be returned if data integrity checking is enabled and either the key or the value is invalid. Otherwise, this always returns true because if a key doesn't exist, it will create a new key-value pair.

**`valueForKey(aKey) -- (object) as object or (missing value)`**

This returns the given value for a key. If it cannot find a value for that key because the key does not exist or some other error, it returns missing value.

**`addValuesForKeys(someValues, someKeys) -- (list, list) -- as boolean`**

This allows the addition of multiple keys and values as lists. If data integrity checking is on, then the subroutine checks to make sure there are no empty lists and that they have a one-to-one relationship with each other (i.e., both list lengths are the same. The order of both is entirely up to you). Any error along those lines returns false and nothing is added to the dictionary. If data integrity is off, the lists are added "as is" and can result in missing value values in the dictionary.

**`dictionaryIntegrityCheck(verboseFlag) -- (boolean) as boolean`**

This is added as a convenience method to check is any values are either null or have empty lists. The verbose flag will send basic information about key-value pairs to the Applescript log when errors are found.
