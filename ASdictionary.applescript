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
    13_01_05_01_02_002:	Switched order of run{} and MakeDictionary() subroutines to make it easier to find actual class
    						Added getValues() subroutine
    						Added getKeysSorted() subroutine
    						Added mergeSort() subroutine
    						Added burn tests for getValues() and getKeysSorted()
    13_01_05_01_02_003: Added "Big" data burn tests to check speed
    13_01_05_01_03_000:	Added removeValueForKey() and removeValuesForKeys(), making this class mutable
    						Added burn tests for removeValueForKey() and removeValuesForKeys()
*)

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
		
		to getKeys() -- (void) as list
			-- keys are in a list seperate from the values so we need only return the list
			return __keys
		end getKeys
		
		on getKeysSorted() -- (void) as list
			set theKeys to getKeys() of me
			set theKeys to __mergeSort(theKeys) of me
			return theKeys
		end getKeysSorted
		
		to getValues() -- (void) as list
			return __values
		end getValues
		
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
		
		to removeValueForKey(aKey) -- (string) as void
			
			-- check if there is a value for the key
			set theIndex to __getIndexForKey(aKey)
			if theIndex = missing value then
				return
			end if
			
			-- if there is a value, replace that item in values with missing value
			set item theIndex of __values to missing value
			set item theIndex of __keys to missing value
			
			-- and replace the key in keys with missing value
			-- go to node in the hash and remove the index of the key-value pair
			
			set lastChr to (count aKey)
			set currentNode to __keyIndexHash of me
			
			repeat with chr from 1 to lastChr
				set nodeIdx to __chrToHashIndex(item chr of aKey) of me
				set currentNode to __getGlyphInNode(currentNode, nodeIdx)
				if currentNode is missing value then
					-- something bad happened that shouldn't have
					return
				end if
				-- we are where the index is located, so we clear the index so it cannot be found again as being valid
				if chr = lastChr then
					set index of currentNode to missing value
				end if
			end repeat
			
		end removeValueForKey
		
		to removeValuesForKeys(keys) -- (list) as void
			set lastKey to (count keys)
			repeat with thisKey from 1 to lastKey
				set theKey to item thisKey of keys
				my removeValueForKey(theKey)
			end repeat
		end removeValuesForKeys
		
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
		
		-- takes a key and returns the index if it exists for that key, else returns missing value
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
		
		(*
			Sort Stack
			Credit: http://www.mailinglistarchive.com/applescript-users@lists.apple.com/msg02255.html
		*)
		
		on __mergeSort(m)
			set n to length of m
			if n ≤ 1 then -- less than or equal to
				return m
			else
				set firstList to {}
				set secondList to {}
				set middleIndex to n div 2
				repeat with x from 1 to middleIndex
					copy item x of m to end of firstList
				end repeat
				repeat with x from middleIndex + 1 to n
					copy item x of m to end of secondList
				end repeat
				set firstList to my __mergeSort(firstList)
				set secondList to my __mergeSort(secondList)
				set resultList to my __merge(firstList, secondList)
				return resultList
			end if
		end __mergeSort
		
		on __merge(leftList, rightList)
			set resultList to {}
			repeat while length of leftList > 0 and length of rightList > 0
				set a to first item of leftList
				set b to first item of rightList
				if a ≤ b then -- less than or equal to
					copy a to end of resultList
					set leftList to rest of leftList
				else
					copy b to end of resultList
					set rightList to rest of rightList
				end if
			end repeat
			if length of leftList > 0 then
				repeat with x in leftList
					copy contents of x to end of resultList
				end repeat
			end if
			if length of rightList > 0 then
				repeat with x in rightList
					copy contents of x to end of resultList
				end repeat
			end if
			return resultList
		end __merge
		
	end script
	
	return ASDictionary
	
end MakeDictionary

(*
	Burn Tests
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
		
		log "set theKeysSorted to getKeysSorted()"
		set theKeysSorted to getKeysSorted()
		log theKeysSorted
		
		log "set theValues to getValues()"
		set theValues to getValues()
		log theValues
		
		log "iterate through all keys"
		set lastKey to (count theKeys)
		repeat with k from 1 to lastKey
			set theKey to item k of theKeys
			set theValue to valueForKey(theKey)
			set theValueByIndex to valueForIndex(k)
			log {theKey, theValue, theValueByIndex}
		end repeat
		
		log "remove the key-value pairs"
		repeat with k from 1 to lastKey
			removeValueForKey(item k of theKeys)
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
	
	
	(*
		"Big" Data Burn Test
		This is to see how fast it handles a larger, probably more realistic, data set.
	*)
	
	set sourceText to "Lorem ipsum dolor sit amet consectetuer adipiscing elit Aenean commodo ligula eget dolor Aenean massa Cum sociis natoque penatibus et magnis dis parturient montes nascetur ridiculus mus Donec quam felis ultricies nec pellentesque eu pretium quis sem Nulla consequat massa quis enim Donec pede justo fringilla vel aliquet nec vulputate eget arcu In enim justo rhoncus ut imperdiet a venenatis vitae justo Nullam dictum felis eu pede mollis pretium Integer tincidunt Cras dapibus Vivamus elementum semper nisi Aenean vulputate eleifend tellus Aenean leo ligula porttitor eu consequat vitae eleifend ac enim Aliquam lorem ante dapibus in viverra quis feugiat a tellus Phasellus viverra nulla ut metus varius laoreet Quisque rutrum Aenean imperdiet Etiam ultricies nisi vel augue Curabitur ullamcorper ultricies nisi Nam eget dui Etiam rhoncus Maecenas tempus tellus eget condimentum rhoncus sem quam semper libero sit amet adipiscing sem neque sed ipsum Nam quam nunc blandit vel luctus pulvinar hendrerit id lorem Maecenas nec odio et ante tincidunt tempus Donec vitae sapien ut libero venenatis faucibus Nullam quis ante Etiam sit amet orci eget eros faucibus tincidunt Duis leo Sed fringilla mauris sit amet nibh Donec sodales sagittis magna Sed consequat leo eget bibendum sodales augue velit cursus nunc quis gravida magna mi a libero Fusce vulputate eleifend sapien Vestibulum purus quam scelerisque ut mollis sed nonummy id metus Nullam accumsan lorem in dui Cras ultricies mi eu turpis hendrerit fringilla Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; In ac dui quis mi consectetuer lacinia Nam pretium turpis et arcu Duis arcu tortor suscipit eget imperdiet nec imperdiet iaculis ipsum Sed aliquam ultrices mauris Integer ante arcu accumsan a consectetuer eget posuere ut mauris Praesent adipiscing Phasellus ullamcorper ipsum rutrum nunc Nunc nonummy metus Vestibulum volutpat pretium libero Cras id dui Aenean ut eros et nisl sagittis vestibulum Nullam nulla eros ultricies sit amet nonummy id imperdiet feugiat pede Sed lectus Donec mollis hendrerit risus Phasellus nec sem in justo pellentesque facilisis Etiam imperdiet imperdiet orci Nunc nec neque Phasellus leo dolor tempus non auctor et hendrerit quis nisi Curabitur ligula sapien tincidunt non euismod vitae posuere imperdiet leo Maecenas malesuada Praesent congue erat at massa Sed cursus turpis vitae tortor Donec posuere vulputate arcu Phasellus accumsan cursus velit Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Sed aliquam nisi quis porttitor congue elit erat euismod orci ac placerat dolor lectus quis orci Phasellus consectetuer vestibulum elit Aenean tellus metus bibendum sed posuere ac mattis non nunc Vestibulum fringilla pede sit amet augue In turpis Pellentesque posuere Praesent turpis Aenean posuere tortor sed cursus feugiat nunc augue blandit nunc eu sollicitudin urna dolor sagittis lacus Donec elit libero sodales nec volutpat a suscipit non turpis Nullam sagittis Suspendisse pulvinar augue ac venenatis condimentum sem libero volutpat nibh nec pellentesque velit pede quis nunc Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Fusce id purus Ut varius tincidunt libero Phasellus dolor Maecenas vestibulum mollis diam Pellentesque ut neque Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas In dui magna posuere eget vestibulum et tempor auctor justo In ac felis quis tortor malesuada pretium Pellentesque auctor neque nec urna Proin sapien ipsum porta a auctor quis euismod ut mi Aenean viverra rhoncus pede Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas Ut non enim eleifend felis pretium feugiat Vivamus quis mi Phasellus a est Phasellus magna In hac habitasse platea dictumst Curabitur at lacus ac velit ornare lobortis Curabitur a felis in nunc fringilla tristique Morbi mattis ullamcorper velit Phasellus gravida semper nisi Nullam vel sem Pellentesque libero tortor tincidunt et tincidunt eget semper nec quam Sed hendrerit Morbi ac felis Nunc egestas augue at pellentesque laoreet felis eros vehicula leo at malesuada velit leo quis pede Donec interdum metus et hendrerit aliquet dolor diam sagittis ligula eget egestas libero turpis vel mi Nunc nulla Fusce risus nisl viverra et tempor et pretium in sapien Donec venenatis vulputate lorem Morbi nec metus Phasellus blandit leo ut odio Maecenas ullamcorper dui et placerat feugiat eros pede varius nisi condimentum viverra felis nunc et lorem Sed magna purus fermentum eu tincidunt eu varius ut felis In auctor lobortis lacus Quisque libero metus condimentum nec tempor a commodo mollis magna Vestibulum ullamcorper mauris at ligula Fusce fermentum Nullam cursus lacinia erat Praesent blandit laoreet nibh Fusce convallis metus id felis luctus adipiscing Pellentesque egestas neque sit amet convallis pulvinar justo nulla eleifend augue ac auctor orci leo non est Quisque id mi Ut tincidunt tincidunt erat Etiam feugiat lorem non metus Vestibulum dapibus nunc ac augue Curabitur vestibulum aliquam leo Praesent egestas neque eu enim In hac habitasse platea dictumst Fusce a quam Etiam ut purus mattis mauris sodales aliquam Curabitur nisi Quisque malesuada placerat nisl Nam ipsum risus rutrum vitae vestibulum eu molestie vel lacus Sed augue ipsum egestas nec vestibulum et malesuada adipiscing dui Vestibulum facilisis purus nec pulvinar iaculis ligula mi congue nunc vitae euismod ligula urna in dolor Mauris sollicitudin fermentum libero Praesent nonummy mi in odio Nunc interdum lacus sit amet orci Vestibulum rutrum mi nec elementum vehicula eros quam gravida nisl id fringilla neque ante vel mi Morbi mollis tellus ac sapien Phasellus volutpat metus eget egestas mollis lacus lacus blandit dui id egestas quam mauris ut lacus Fusce vel dui Sed in libero ut nibh placerat accumsan Proin faucibus arcu quis ante In consectetuer turpis ut velit Nulla sit amet est Praesent metus tellus elementum eu semper a adipiscing nec purus Cras risus ipsum faucibus ut ullamcorper id varius ac leo Suspendisse feugiat Suspendisse enim turpis dictum sed iaculis a condimentum nec nisi Praesent nec nisl a purus blandit viverra Praesent ac massa at ligula laoreet iaculis Nulla neque dolor sagittis eget iaculis quis molestie non velit Mauris turpis nunc blandit et volutpat molestie porta ut ligula Fusce pharetra convallis urna Quisque ut nisi Donec mi odio faucibus at scelerisque quis"
	
	set wordCountDictionary to MakeDictionary() of me
	
	set wordList to SplitString(sourceText, " ") of me
	set lastWord to (count wordList)
	
	--catalog word counts
	tell wordCountDictionary
		repeat with thisWord from 1 to lastWord
			set theWord to item thisWord of wordList
			set theCount to valueForKey(theWord)
			if theCount is missing value then
				set theCount to 0
			end if
			set theCount to theCount + 1
			setValueForKey(theCount, theWord)
		end repeat
	end tell
	
	my logKeysAndValuesInDictionary(wordCountDictionary)
	
	set characterCountDictionary to MakeDictionary() of me
	
	tell characterCountDictionary
		set lastChar to (count sourceText)
		log {lastChar:lastChar}
		repeat with thisChar from 1 to lastChar
			set theChar to item thisChar of sourceText
			set theCount to valueForKey(theChar)
			if theCount is missing value then
				set theCount to 0
			end if
			set theCount to theCount + 1
			setValueForKey(theCount, theChar)
		end repeat
	end tell
	
	my logKeysAndValuesInDictionary(characterCountDictionary)
	
end run

(*
	Helper Subroutines
	Just a little something to help crunch through the "big" data
*)

on logKeysAndValuesInDictionary(dict)
	set theKeys to getKeysSorted() of dict
	set lastKey to (count theKeys)
	repeat with k from 1 to lastKey
		set theKey to item k of theKeys
		set theValue to valueForKey(theKey) of dict
		log {theKey, theValue}
	end repeat
end logKeysAndValuesInDictionary

on SplitString(theString, TheDelimiter) -- (string, string) as list
	set AppleScript's text item delimiters to {TheDelimiter}
	set theStringList to (every text item in theString) as list
	set AppleScript's text item delimiters to ""
	return theStringList
end SplitString

