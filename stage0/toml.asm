;this achieves the functionality of an enum
struc toml_state
.root: resb 1	;entries go into the root table
.table: resb 1 ;entries go into a table
.keyEntry: resb 1
.keyWord: resb 1	;look for . or = of a key
.findValueOfPair: resb 1
.value: resb 1
.tableName: resb 1
.quote1: resb 1
.quote2: resb 1
.blankKey: resb 1
.done: resb 1 ;done parsing
endstruc

;this achieves the functionality of an enum
;the numbers here are used as bitflags (1<<toml_flags.xxxx)
struc toml_flags
.comment: resb 1 ;the parser is in comment mode for now
.quote1: resb 1 ;the parser is in single ' mode
.quote2: resb 1 ;the parser is in single " mode
.escape: resb 1 ;the parser is in escape sequence mode for a string
.uni1: resb 1 ;unicode character
.uni2: resb 1 ;unicode character
.uni3: resb 1 ;unicode character
.uni4: resb 1 ;unicode character
.uni5: resb 1 ;unicode character
.uni6: resb 1 ;unicode character
.uni7: resb 1 ;unicode character
.uni8: resb 1 ;unicode character
endstruc

;this achieves the functionality of an enum
struc toml_symbols
.whitespace: resb 1 ; space or tab
.newline2: resb 1 ;the 0x0d character
.newline: resb 1 ;the 0x0a character
.validComment: resb 1 ;everything except for control characters
.controls: resb 1 ;control characters except for tab and newline
.octothorpe: resb 1 ;the octothorpe symbol #
.period: resb 1 ;the .
.basicChars: resb 1 ;a-zA-Z0-9_-
.equals: resb 1 ;the = symbol
.quote1: resb 1 ;the ' symbol
.quote2: resb 1 ;the " symbol
.backslash: resb 1 ;the \ symbol
.eof: resb 1 ;represents that there is no more data in the file to process
.lsquare: resb 1 ;the [
.rsquare: resb 1 ; the ]
.basicStringChars: resb 1 ;the opposite of "?\ and .controls
.singleEscape: resb 1 	;the single character escape sequences btnfr"\
.uniEscape1: resb 1	;the u
.uniEscape2: resb 1	;the U
endstruc




;state machine transitions and events
;current state			symbol type			new state		event?
;toml_state.root		toml_symbols.quote1		toml_state.quote1	no
;toml_state.root		toml_symbols.quote2		toml_state.quote2	no
;toml_state.root		toml_symbols.octothorpe		(same)			set toml_flag.comment
;toml_state.root		toml_symbols.basicChars		toml_state.keyEntry	add character to key
;toml_state.root		toml_symbols.equals		?			error key name missing
;toml_state.root		toml_symbols.lsquare		toml_state.tableName	no
;toml_state.root		toml_symbols.eof		toml_state.done		?

;toml_flag.comment		toml_symbols.validComment	(same)			no
;toml_flag.comment		toml_symbols.controls		(same)			invalid character in comment
;toml_flag.comment		toml_symbols.newline2		(same)			no
;toml_flag.comment		toml_symbols.newline		(same)			clear toml_flag.comment
;toml_flag.comment		toml_symbols.eof		toml_state.done		?
;toml_flag.comment		(others)			(same)			invalid character in comment

;toml_state.keyEntry		toml_symbols.basicChars		(same)			no
;toml_state.keyEntry		toml_symbols.whitespace		toml_state.keyWord	no
;toml_state.keyEntry		toml_symbols.period		(same)			parse for dotted keys
;toml_state.keyEntry		toml_symbols.newline2		(same)			no
;toml_state.keyEntry		toml_symbols.newline		(same)			key value not specified
;toml_state.keyEntry		toml_symbols.octothorpe		toml_state.comment	key value not specified
;toml_state.keyEntry		toml_symbols.eof		toml_state.done		key value not specified
;toml_state.keyEntry		toml_symbols.quote1		(same)			set toml_flag.quote1
;toml_state.keyEntry		toml_symbols.quote2		(same)			set toml_flag.quote2
;toml_state.keyEntry		toml_symbols.equals		toml_state.value	finish keyname

;toml_flag.quote1 +
;toml_state.keyEntry

;toml_flag.quote2 +		toml_symbols.basicStringChars	(same)			no
;toml_state.keyEntry

;toml_flag.quote2 +		toml_symbols.backslash		(same)			set toml_flag.escape
;toml_state.keyEntry

;toml_flag.quote2 +		toml_symbols.singleEscape	(same)			clear toml_flag.escape
;toml_flags.escape +
;toml_state.keyEntry

;toml_flag.quote2 +		toml_symbols.uniEscape1
;toml_flag.escape +
;toml_state.keyEntry

;toml_state.keyWord		toml_symbols.whitespace		(same)			no
;toml_state.keyWord		toml_symbols.period		toml_state.keyEntry	parse for dotted keys
;toml_state.keyWord		toml_symbols.equals		toml_state.value	finish keyname

