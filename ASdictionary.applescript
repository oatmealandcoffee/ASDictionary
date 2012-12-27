(*
Project: ASDictionary: A pure Applescript dictionary class to pick up where the record class left off
Author(s): Philip Regan
License: Copyright 2012 Philip Regan, http://www.oatmealandcoffee.com
Source:	New source only; no adaptations.
Requirements: None
Notes:

Maintaining and checking key-value parity:
Since keys and values are stored separatly, we have to occasionally check for parity between the two lists in case of unintended or uncontrollable errors when setting values.  Since we cannot access values directly by the values themselves, we use the keys as the benchmark for checking parity. Obviously, this is a problem if the __values list is shorter than the __keys list, but we have to start somewhere. There is the dictionaryIntegrityCheck() subroutine, but this can be overkill especially when methods are expected to be fast.

Change History:
    12_12_10_01_00_000: Started public source
    12_12_10_01_00_001: Changed remaining mentions of kASDictionary_ValueNotFound to missing value
    						Added header comments
    12_12_27_01_01_000:	Removed key-value records
    						Added separate lists for keys and values. This optimizes the returning of stored keys to simply returning the internal property as opposed to iterating through all records to get the keys
    						Updated methods to handle separate lists for keys and values
    12_12_27_01_02_000: Added valueForIndex() subroutine
    						Added burn test for valueForIndex()
    12_12_27_01_02_001:	Updated valueForIndex() to handle list indexes that are ≤ 1.
*)

on run {}
	
	set testDictionary to MakeDictionary() of me
	
	tell testDictionary
		
		(* Basic Operations *)
		
		(* Add a value and Key *)
		
		log "setValueForKey(oop, OOP)"
		set valueForKeySet to setValueForKey("oop", "OOP")
		log valueForKeySet
		
		(* Add a list of values and keys *)
		
		log "addValuesForKeys({ack, greeble, ponies}, {ACK, GREEBLE, PONIES})"
		set valuesAddedForKeys to addValuesForKeys({"ack", "greeble", "ponies"}, {"ACK", "GREEBLE", "PONIES"})
		log valuesAddedForKeys
		
		(* Get and set values for keys *)
		
		log "setValueForKey(\"Luc Teyssier\", OOP)"
		set valueSetForKey to setValueForKey("Luc Teyssier", "OOP")
		log valueSetForKey
		
		log "set myValueForKey to valueForKey(OOP)"
		set myValueForKey to valueForKey("OOP")
		log myValueForKey
		
		(* Get all of the keys and iterate through the pairs *)
		
		log "set theKeys to getKeys()"
		set theKeys to getKeys()
		log theKeys
		
		log "iterate through all keys"
		set lastKey to (count theKeys)
		repeat with k from 1 to lastKey
			set theKey to item k of theKeys
			set theValue to valueForKey(theKey)
			set theValueByIndex to valueForIndex(k)
			log {theKey, theValue, theValueByIndex}
		end repeat
		
		(* Operations That Will Cause Errors *)
		
		log "toggleDataIntegrityChecks()"
		log toggleDataIntegrityChecks()
		
		log "setValueForKey(emptyValueList, emptyKeyList)"
		log setValueForKey({}, {})
		-- nothing should be added to keys or values, 
		-- but since we turned off data integrity checks, 
		-- we get it added but the report catches it
		
		log "addValuesForKeys(unmatchedValueList, unmatchedKeyList)"
		log addValuesForKeys({"Kate", "Charlie"}, {"Jean-Paul Cardon", "Bob", "Juliette", "Concierge"})
		-- we should see errors in the log and nothing added
		
		log "keyFound to hasKey(supercalifrajilisticexpialidocious)"
		set keyFound to hasKey("supercalifrajilisticexpialidocious")
		log keyFound
		-- we should get back a false here
		
		log "set theValueForKey to valueForKey(supercalifrajilisticexpialidocious)"
		set theValueForKey to valueForKey("supercalifrajilisticexpialidocious")
		log theValueForKey
		-- we should get back missing value here
		
		(* Check to make sure our data is clean so we don't mess up operations later *)
		
		log "set dictionaryIsSafe to dictionaryIntegrityCheck(true)"
		set dictionaryIsSafe to dictionaryIntegrityCheck(true)
		log dictionaryIsSafe
		
	end tell
	
end run

on MakeDictionary() -- as ASDictionary
	
	script ASDictionary
		
		(* Private properties *)
		
		property __keys : {}
		property __values : {}
		
		property __checkDataIntegrity : true
		
		(* Public SubRoutines *)
		
		to hasKey(aKey) -- (object) as boolean
			
			set keyValueIndex to __getIndexForKey(aKey) of me
			
			if keyValueIndex is missing value then
				return false
			end if
			
			return true
		end hasKey
		
		to toggleDataIntegrityChecks() -- as boolean
			if __checkDataIntegrity = true then
				set __checkDataIntegrity to false
			else
				set __checkDataIntegrity to true
			end if
			return __checkDataIntegrity
		end toggleDataIntegrityChecks
		
		to getKeys() -- as list
			-- keys are in a list seperate from the values so we need only return the list
			return __keys
		end getKeys
		
		to setValueForKey(aValue, aKey) -- (object, object) as boolean
			
			if __checkDataIntegrity then
				set aValuePassed to __dataIntegrityCheck(aValue)
				set aKeyPassed to __dataIntegrityCheck(aKey)
				if not aValuePassed or not aKeyPassed then return false
			end if
			
			set keyValueIndex to __getIndexForKey(aKey) of me
			
			if keyValueIndex is missing value then
				
				set end of __values to aValue
				set end of __keys to aKey
				
				set keyValuePairsCount to count __keys
				my __setKeyAndIndexToHash(aKey, keyValuePairsCount)
			else
				
				set item keyValueIndex of __values to aValue
			end if
			
			return true
			
		end setValueForKey
		
		to valueForKey(aKey) -- (object) as object or (missing value)
			
			set keyValueIndex to __getIndexForKey(aKey) of me
			
			if keyValueIndex is missing value then
				return missing value
			end if
			
			return item keyValueIndex of __values
			
		end valueForKey
		
		to valueForIndex(anIndex) -- (integer) as object or (missing value)
			
			set keysCount to count __keys
			
			-- we do not make any assumptions about how they got their index, so we simply check
			if (anIndex < 1) or (anIndex > keysCount) then
				return missing value
			end if
			
			return item anIndex of __values
			
		end valueForIndex
		
		to addValuesForKeys(someValues, someKeys) -- (list, list) -- as boolean
			
			set keysCount to (count someKeys)
			set valuesCount to (count someValues)
			
			if __checkDataIntegrity then
				
				if keysCount is not equal to valuesCount then return false
				if keysCount = 0 and valuesCount is not equal to 0 then return false
				if keysCount is not equal to 0 and valuesCount = 0 then return false
				
			end if
			
			set keysCount to (count someKeys)
			repeat with thisKey from 1 to keysCount
				try
					set theKey to item thisKey of someKeys
					set theValue to item thisKey of someValues
					set theResult to setValueForKey(theValue, theKey) of me
				on error
					-- fail silently
				end try
			end repeat
			
			return true
		end addValuesForKeys
		
		to dictionaryIntegrityCheck(verboseFlag) -- (boolean) as boolean
			
			set dictionaryIsClean to true
			
			set keysCount to count __keys
			set valuesCount to count __values
			
			-- there is nothing in the key-value lists to check, and that is as clean as it can get
			if (keysCount = 0 and valuesCount = 0) then
				return dictionaryIsClean
			end if
			
			if (keysCount is not equal to valuesCount) then
				set dictionaryIsClean to false
				if (verboseFlag) then
					log "ASDictionary ERROR: The number of keys does not equal the number of values. {keys:" & keysCount & ", values:" & valuesCount & "}"
				end if
				-- we still want to check the key-value pairs, but we need to work around any OutOfBounds errors
				if (valuesCount < keysCount) then
					set keysCount to valuesCount
				end if
			end if
			
			repeat with thisKey from 1 to keysCount
				(* DEPRECATED
				set theKeyValuePair to item thisKeyValuePair of __keyValuePairs
				*)
				set theKey to item thisKey of __keys
				set theValue to item thisKey of __values
				
				set theKeyPassed to __dataIntegrityCheck(theKey)
				set theValuePassed to __dataIntegrityCheck(theValue)
				
				if not theKeyPassed or not theValuePassed then
					set dictionaryIsClean to false
					
					if verboseFlag then
						
						log ("ASDictionary ERROR: A key-value pair had an error: index: " & thisKey & ", key:" & theKey as string) & ", value:" & theValue as string
						
					end if
				end if
			end repeat
			
			return dictionaryIsClean
		end dictionaryIntegrityCheck
		
		(* 
		Private Subroutines
		All error checking is done before we get to these methods, so these should not be called directly.
		*)
		
		to __dataIntegrityCheck(newData) -- (object) as boolean
			(* This offers only very basic checks: null or empty lists *)
			
			if newData = null or newData = missing value then
				return false
			end if
			
			try
				set itemCount to (count newData)
				if itemCount = 0 then
					return false
				end if
			on error
				-- fail silently
			end try
			
			return true
		end __dataIntegrityCheck
		
		-- this is created in __setKeyAndIndexToHash when we actually need it.
		property __keyIndexHash : {}
		
		-- Unicode support: 0123456789:'<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz
		property __val_0 : 48
		property __val_9 : 57
		property __upper_a : 65
		property __upper_z : 90
		property __upper_offset : 7 -- deprecated
		property __lower_a : 97
		property __lower_z : 122
		property __lower_offset : 13 -- deprecated
		property __unsupported_chr : __lower_z - __val_0 + 1
		
		on __makeGlyphNode() -- (void) as node
			(*
			index: the index in the key-value pairs list. 0 means there is not a key that exists
			nodes: the used characters for the keys
			*)
			set nodeList to {}
			repeat with i from 1 to __unsupported_chr
				set end of nodeList to missing value
			end repeat
			set theNode to {index:missing value, nodes:nodeList}
			return theNode
		end __makeGlyphNode
		
		on __makeGlyphInNode(parentNode, idx) --(node, int) as node
			
			-- check to see if there is already a node at that location
			set foundNode to item idx of nodes of parentNode
			if (foundNode is not missing value) then
				return foundNode
			end if
			-- make a new node if one isn't found
			set newNode to __makeGlyphNode() of me
			set item idx of nodes of parentNode to newNode
			return newNode
		end __makeGlyphInNode
		
		on __getGlyphInNode(parentNode, idx) --(node, int) as node
			return item idx of nodes of parentNode
		end __getGlyphInNode
		
		
		-- records the key into the hash table
		on __setKeyAndIndexToHash(key, idx) --(string, int) as void
			
			-- init the root has if need be
			if (count __keyIndexHash) = 0 then
				set __keyIndexHash to __makeGlyphNode() of me
			end if
			
			-- get the root as a place to kick off
			set newNode to __keyIndexHash
			
			-- iterate through the string
			set lastChr to (count key)
			repeat with chr from 1 to lastChr
				set nodeIdx to __chrToHashIndex(item chr of key) of me
				set newNode to __makeGlyphInNode(newNode, nodeIdx) of me
				if chr = lastChr then
					set index of newNode to idx
				end if
				
			end repeat
			
		end __setKeyAndIndexToHash
		
		-- takes a key and returns the index if it exists for that key, else returns 0
		on __getIndexForKey(key) -- (string) as int or missing value
			
			if (count __keyIndexHash) = 0 then
				return missing value
			end if
			
			set currentNode to __keyIndexHash
			set idx to missing value
			set lastChr to (count key)
			
			repeat with chr from 1 to lastChr
				set nodeIdx to __chrToHashIndex(item chr of key) of me
				set currentNode to __getGlyphInNode(currentNode, nodeIdx)
				if currentNode is missing value then
					return missing value
				end if
				set idx to index of currentNode
			end repeat
			
			return idx
			
		end __getIndexForKey
		
		-- converts a char to its unicode equivalent, then a value useful to the hash
		on __chrToHashIndex(chr) -- (string) as int
			
			-- get the unicode value of the character
			set val to ((id of chr) - __val_0)
			
			if val ≥ __unsupported_chr or val ≤ 1 then
				set val to __unsupported_chr
			end if
			
			return val
			
		end __chrToHashIndex
		
	end script
	
	return ASDictionary
	
end MakeDictionary
