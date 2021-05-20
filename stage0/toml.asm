;this achieves the functionality of an enum
struc toml_state
.root: resb 1	;entries go into the root table
.table: resb 1 ;entries go into a table
.comment: resb 1
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
endstruc



;state machine transitions and events
;current state			symbol type			new state		event?
;toml_state.root		toml_symbols.quote1		toml_state.quote1	no
;toml_state.root		toml_symbols.quote2		toml_state.quote2	no
;toml_state.root		toml_symbols.octothorpe		toml_state.comment	no
;toml_state.root		toml_symbols.basicChars		toml_state.keyEntry	add character to key
;toml_state.root		toml_symbols.equals		?			error key name missing
;toml_state.root		toml_symbols.lsquare		toml_state.tableName	no
;toml_state.root		toml_symbols.eof		toml_state.done		?

;toml_state.comment		toml_symbols.validComment	(same)			no
;toml_state.comment		toml_symbols.controls		(same)			invalid character in comment
;toml_state.comment		toml_symbols.newline2		(same)			no
;toml_state.comment		toml_symbols.newline		(previous state)	no
;toml_state.comment		toml_symbols.eof		toml_state.done		?

;toml_state.keyEntry		toml_symbols.basicChars		(same)			no
;toml_state.keyEntry		toml_symbols.whitespace		toml_state.keyWord	no
;toml_state.keyEntry		toml_symbols.period		(same)			no
;toml_state.keyEntry		toml_symbols.newline2		(same)			no
;toml_state.keyEntry		toml_symbols.newline		(same)			key value not specified
;toml_state.keyEntry		toml_symbols.octothorpe		toml_state.comment	key value not specified
;toml_state.keyEntry		toml_symbols.eof		toml_state.done		key value not specified

