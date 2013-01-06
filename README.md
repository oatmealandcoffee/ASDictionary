ASDictionary
============

**A pure Applescript dictionary class to pick up where the record class left off**

About
=====

The `record` class in Applescript is, at its core, a dictionary—a key-value pairing of data—but with strict limitations:

* Keys are hard-coded, requiring the script to know all the keys before runtime.
* Records are not dynamic except for changing values for keys. There is no way to add or remove key-value pairs.
* There is no way to iterate through keys or values. Functions like length and count give the number of records, but then there is no ability to call values by index.

`ASDictionary` addresses most of this with a simple-to-use, yet entirely Applescript-native code. There is no need to take on the weight of an ApplescriptObjC application with Xcode's bare bones debugging tools to gain access to `NSDictionary` and `NSMutableDictionary` classes, and instead keep working with more developer-friendly tools like Script Debugger.

Road Map
========

In general, I would like to align functionality with mutable dictionary classes like I see in Cocoa's `NSDictionary`/`NSMutableDictionary` classes and REALbasic's `Dictionary` class, but the short, hard-defined list follows.

**N.B.:** The following list is not given in any particular priority, but is rather organized simply by idea source. Actual functions may vary as needed.

* From `NSDictionary`
	* `description() -- (void) as string`
		* Provides a string in the list format of all keys and values for the dictionary
* From `NSMutableDictionary`
	* `addEntriesFromDictionary(dictionary) -- (ASDictionary) as void`
		* accepts a dictionary for population; duplicate keys are overwritten
	* `removeAllObjects() -- (void) as void`
		* removes all key-value pairs and resets the key hash; the nuclear option
* From personal work
	* `reindex() -- (void) as void`
		* optimization that removes empty values from the `__keys` and `__values` lists and creates a new key hash; gives the developer a way to save memory during runtime
* Still-nebulous features
	* *Better error reporting.* Right now, it only uses `missing value`, which isn't very informative as a few things can go wrong but at least it is Applescript-native. I had errors in the previous iteration but I just didn't like how they were handled.
	* *Optimize hash table management*, particularly as it creates wholly empty lists that never get used during runtime, but it is fast (for Applescript) and it works.

Documentation
=============

**Introduction**

Essentially, `ASDictionary` is a wrapper for two private lists of keys and values and maintains parity between them. In other words, the key placed at index *n* of the keys list is matched to the value at place *n* in the values list. When a key value pair is created, the pair components are placed at the end of their respective `list` and the index recorded in the hash table by the key.

*The keys list rules all when checking for parity and data integrity.* If the keys list is shorter than the values list, then values will be lost unless the developer maintains a count of values placed.

Retrieving values is nothing more than seeing if each character for a given key has a place in the hash table, getting the index on the last character, and returning the value for that pair. When in doubt about anything, the dictionary returns *`missing value`*.

**Caveats**

*Script Objects and memory*

This uses the `Script Object` features of Applescript, which allows custom OOP in Applescript complete with inheritance. The caveat is that doing this can be very resource and memory intensive.

If you are not familiar with `Script Objects`, then I highly suggest you read the Applescript Language Guide. Suffice to say, however, that all of the action, the class in of itself, is held within the `script ASDictionary...end script` block within the `MakeDictionary()` subroutine.

*Unicode Key Support*

Applescript's text class supports Unicode, moving from ASCII a while ago. Unicode is much broader in scope over ASCII, but `ASDictionary` still checks to be sure that keys are built using an ASCII-centric character set. The currently supported characters include Unicode value 48 (`'0'`) contiguously through 122 (`'z'`) shown in order here:

    0123456789:'<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz

This limitation is based on `ASDictionary's` current iteration requiring each node in the hash table hold an array aligned with the numerical value of each character regardless if the array is populated. Supporting the full Unicode set would consume far too much memory even for the shallowest of tables, so sticking with characters 48 through 122 maintains a manageable but still useful character set.

*Convenience Methods*

Script objects cannot instantiate themselves as in Cocoa, a single function is provided to kick things off, but convenience methods are trivial to create:

```
on MakeDictionaryWithValuesAndKeys(someValues, someKeys) -- (list, list) as ASDictionary
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

**`MakeDictionary() -- as ASDictionary`**

If Script Objects are to be used, they need to be declared and returned, and that is all this subroutine does. This contains the entire ASDictionary declaration, so just copy and paste into your script and call with the simple
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

**`valueForIndex(anIndex) -- (integer) as object or (missing value)`**

Returns the value for a given index. If the index is out of the bounds of the keys array, then it returns missing value. Else, it returns whatever is contained at the index of the values array.

**`addValuesForKeys(someValues, someKeys) -- (list, list) -- as boolean`**

This allows the addition of multiple keys and values as lists. If data integrity checking is on, then the subroutine checks to make sure there are no empty lists and that they have a one-to-one relationship with each other (i.e., both list lengths are the same. The order of both is entirely up to you). Any error along those lines returns false and nothing is added to the dictionary. If data integrity is off, the lists are added "as is" and can result in missing value values in the dictionary.

**`removeValueForKey(aKey) -- (string) as void`**

Replace the key-value pair in their respective lists with missing value. This also deletes the index in the hash, though the letters that made up the key are still in place.

**`removeValuesForKeys(keys) -- (list) as void`**

Allows the removal of multiple keys and values as lists.

**`dictionaryIntegrityCheck(verboseFlag) -- (boolean) as boolean`**

This is added as a convenience method to check is any values are either null or have empty lists. The verbose flag will send basic information about key-value pairs to the Applescript log when errors are found.
