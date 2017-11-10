/'
 * 
 * Copyright (c) 2007-2017 Jeffery R. Marshall.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'/

#include once "lisp_int.bi"
#include once "lisp_err.bi"
#include once "lisp_ctx.bi"

#include once "lisp_lexer.bi"

namespace LISP

''
#define LEX_CHAR_EOF -1


'' !!! FIXME: Add ref counting

'' ---------------------------------------------------------------------------
'' LEXER_CTX
'' ---------------------------------------------------------------------------

type LISP_LEXER_CTX_STATE

	declare constructor( )
	declare destructor( )
	
	buffer as string		'' The buffer to lex/parse
	filename as string      '' current filename
	lineno as integer		'' current line number
	column as integer		'' current column number
	index0 as integer		'' last marked index
	index1 as integer		'' current index in the buffer

	token_id as LISP_TOKEN_ID    '' id of last token found
	token as string			     '' text of last token found

	previous as LISP_LEXER_CTX_STATE ptr

	declare function gettoken( ) as LISP_TOKEN_ID
	declare function getchar( ) as integer
	declare function peekchar( ) as integer
	declare function peekchar( byval index as integer ) as integer
	declare function getcomment( ) as LISP_TOKEN_ID
	declare function lexidentifier( ) as LISP_TOKEN_ID
	declare function lexnumber( ) as LISP_TOKEN_ID
	declare function getstring( ) as LISP_TOKEN_ID

end type

type LISP_LEXER_CTX

	declare constructor( )
	declare constructor( byval parent_ctx as LISP_CTX ptr )
	declare destructor( )

	declare sub settext( byref buffer as string ) 

	parent as LISP_CTX ptr

	state as LISP_LEXER_CTX_STATE ptr

end type

''
private constructor LISP_LEXER_CTX_STATE()

	previous = NULL

	buffer = ""
	filename = ""
	lineno = 0
	column = 0
	index0 = 0
	index1 = 0

	token_id = LISP_TK_INVALID
	token = ""

end constructor

''
private destructor LISP_LEXER_CTX_STATE()
	
	buffer = ""
	filename = ""
	token = ""

end destructor

''
private constructor LISP_LEXER_CTX( byval parent_ctx as LISP_CTX ptr )

	parent = parent_ctx

	state = new LISP_LEXER_CTX_STATE()

end constructor

''
private destructor LISP_LEXER_CTX( )

	while( state <> NULL )
		dim state_previous as LISP_LEXER_CTX_STATE ptr = state->previous
		delete state
		state = state_previous
	wend
	state = NULL

end destructor

''
private function LISP_LEXER_CTX_STATE.getchar() as integer
	if( index1 < len(buffer) ) then
		function = buffer[index1]
		index1 += 1
		column += 1
	else
		function = LEX_CHAR_EOF
	end if
end function

''
private function LISP_LEXER_CTX_STATE.peekchar() as integer
	if( index1 < len(buffer ) ) then
		function = buffer[index1]
	else
		function = LEX_CHAR_EOF
	end if
end function

''
private function LISP_LEXER_CTX_STATE.peekchar( byval index as integer) as integer
	if( index1 + index < len(buffer) ) then
		function = buffer[index1 + index]
	else
		function = LEX_CHAR_EOF
	end if
end function

''
private function LISP_LEXER_CTX_STATE.getcomment() as LISP_TOKEN_ID
	dim c as integer = any

	'' ';'?
	c = getchar()

	do
		c = getchar()
		select case c
		case 13
			c = peekchar()
			if( c = 10 ) then
				c = getchar()
			end if
			lineno += 1
			column = 0
			exit do
		case 10
			lineno += 1
			column = 0
			exit do
		case LEX_CHAR_EOF
			exit do
		end select
	loop

	token = mid( buffer, index0 + 1, index1 - index0 )
	function = LISP_TK_COMMENT

end function

''
private function LISP_LEXER_CTX_STATE.lexnumber() as LISP_TOKEN_ID

	dim as integer c = any
	dim as boolean have_dec = false
	dim as boolean have_exp = false

	function = LISP_TK_INVALID

	c = peekchar()

	'' '+', '-'
	if( c = 43 or c = 45 ) then
		c = getchar()
		c = peekchar()
	end if

	'' test for following patterns
	'' #
	'' #.
	'' #.#
	'' .#

	'' [0-9]
	if( c >= 48 and c <= 57 ) then

		'' [0-9]
		while( c >= 48 and c <= 57 )
			c = getchar()
			c = peekchar()
		wend

		'' '.'
		if( c = 46 ) then
			have_dec = true
			c = getchar()
			c = peekchar()
		end if

		'' [0-9]
		while( c >= 48 and c <= 57 )
			c = getchar()
			c = peekchar()
		wend

	'.'
	elseif( c = 46 ) then

		c = getchar()
		c = peekchar()

		'' [0-9]
		if( c >= 48 and c <= 57 ) then
			have_dec = true

			'' [0-9]
			while( c >= 48 and c <= 57 )
				c = getchar()
				c = peekchar()
			wend

		else
			'' invalid number
			exit function

		end if

	else
		'' invalid number
		exit function

	end if

	'' [DEde]
	select case c
	case 68, 69, 100, 101

		c = getchar()	'' [DEde]
		c = peekchar()

		'' '+', '-'		
		if( c = 43 or c = 45 ) then
			c = getchar()
			c = peekchar()
		end if

		'' [0-9]
		if( c >= 48 and c <= 57 ) then

			'' [0-9]
			while( c >= 48 and c <= 57 )
				c = getchar()
				c = peekchar()
			wend

		else
			'' invalid number
			exit function

		end if

	end select

	if( have_dec or have_exp ) then
		function = LISP_TK_REAL
	else	
		function = LISP_TK_INTEGER
	end if

end function

''
private function LISP_LEXER_CTX_STATE.lexidentifier( ) as LISP_TOKEN_ID

	dim c as integer = any
	dim index2 as integer = index1

	do
		c = peekchar()
		select case c

		'' [.-/+*%<>=&A-Za-z_0-9]
		case 46, 45, 47, 43, 42, 37, 60, 62, 61, 38, 65 to 90, 97 to 122, 95, 48 to 57
			c = getchar()
		case else
			exit do
		end select
	loop

	if( index2 <> index1 ) then
		function = LISP_TK_IDENTIFIER
	else
		function = LISP_TK_INVALID
	end if

end function

''
private function LISP_LEXER_CTX_STATE.getstring( ) as LISP_TOKEN_ID

	dim c as integer = any

	'' '"'
	c = getchar()

	do
		c = getchar()

		select case c
		
		'' '\'
		case 92
			c = getchar()
			select case c
			case 97  '' a => alert
				token &= chr(7)

			case 98  '' b => backspace
				token &= chr(8)

			case 101 '' e => escape
				token &= chr(27)

			case 102 '' f => form feed
				token &= chr(12)

			case 110 '' n => line feed
				token &= chr(10)

			case 114 '' r => carriage return
				token &= chr(13)

			case 116 '' t => horizontal tab
				token &= chr(9)

			case 118 '' v => vertical tab
				token &= chr(11)

			case else
				token &= chr(c)

			end select

		case 13
			token &= chr(c)
			c = peekchar()
			if( c = 10 ) then
				c = getchar()
				token &= chr(c)
			end if
			lineno += 1
			column = 0

		case 10
			token &= chr(c)
			lineno += 1
			column = 0

		case 34
			exit do

		case LEX_CHAR_EOF
			exit do

		case else
			token &= chr(c)

		end select

	loop

	function = LISP_TK_STRING
	
end function

''
private function LISP_LEXER_CTX_STATE.gettoken( ) as LISP_TOKEN_ID

	dim as integer c
	dim as LISP_TOKEN_ID tk, tktest

	function = LISP_TK_EOF

	token = ""

	do
		index0 = index1
		c = peekchar()
	
		select case c

		case LEX_CHAR_EOF
			exit do

		'' '\r'
		case 13
			c = getchar()
			c = peekchar()
			if( c = 10 ) then
				c = getchar()
			end if
			lineno += 1
			column = 0

		'' '\n'
		case 10
			c = getchar()
			lineno += 1
			column = 0

		'' ' ', '\f', '\t', '\v'
		case 32, 12, 9, 11
			c = getchar()

		'' ';' comment
		case 59
			function = getcomment()

		'' '?'
		case 63 
			c = getchar()
			c = getchar()
			token = ltrim(str(c))
			function = LISP_TK_INTEGER
			exit do

		'' '-', '+', [0-9]
		case 45, 43, 48 to 57

			'' might be a number, so check that first
			tk = lexnumber()

			if( tk = LISP_TK_INVALID ) then
				'' must be identifier, lex additional identifier characters
				tk = lexidentifier()
				tk = LISP_TK_IDENTIFIER
			else
				'' it's a number, but check for additional characters
				'' that would make it an identifier
				tktest = lexidentifier()
				if( tktest <> LISP_TK_INVALID ) then
					tk = tktest
				end if
			end if

			token = mid( buffer, index0 + 1, index1 - index0 )
			function = tk

			exit do

		'' [-/+*%<>=&A-Za-z_]
		case 45, 47, 43, 42, 37, 60, 62, 61, 38, 65 to 90, 97 to 122, 95
			function = lexidentifier()
			token = mid( buffer, index0 + 1, index1 - index0 )
			exit do

		'' single_quote, '(', ')'
		case 39, 40, 41

			c = getchar()
			token = chr( c )
			select case c
			case 39
				function = LISP_TK_SINGLE_QUOTE
			case 40
				function = LISP_TK_LEFT_PARA
			case 41
				function = LISP_TK_RIGHT_PARA
			end select
			
			exit do

		'' '.'
		case 46

			'' might be a number, so check that first
			tk = lexnumber()

			if( tk = LISP_TK_INVALID ) then
				'' not a number, but it might be an identifier, but
				'' we might have read some number parts, so reset
				'' the lexer to the last mark, get the initial '.'
				'' and then try to lex additional identifier characters

				index1 = index0
				c = getchar()
				tk = lexidentifier()

				if( tk = LISP_TK_INVALID ) then
					'' OK, really is just a dot
					index1 = index0
					c = getchar()
					tk = LISP_TK_DOT
				end if

			else
				'' it's a number, but check for additional characters
				'' that would make it an identifier
				tktest = lexidentifier()
				if( tktest <> LISP_TK_INVALID ) then
					tk = tktest
				end if
			end if

			token = mid( buffer, index0 + 1, index1 - index0 )
			function = tk

			exit do

		case 34 '' '\"'
			function = getstring()
			exit do

		case else
			c = getchar()
			token = chr(c)
			function = LISP_TK_CHAR
			exit do

		end select

	loop

end function


'' ---------------------------------------------------------------------------
'' LEXER
'' ---------------------------------------------------------------------------

''
constructor LISP_LEXER( byval parent_ctx as LISP_CTX ptr )
	ctx = new LISP_LEXER_CTX( parent_ctx )
end constructor

''
destructor LISP_LEXER( )
	delete ctx
end destructor

''
sub LISP_LEXER.push( byref f as const string )
	dim next_state as LISP_LEXER_CTX_STATE ptr = new LISP_LEXER_CTX_STATE()
	next_state->previous = ctx->state
	ctx->state = next_state
	ctx->state->filename = f
end sub

''
sub LISP_LEXER.pop( )
	dim state_previous as LISP_LEXER_CTX_STATE ptr = ctx->state->previous
	delete ctx->state
	ctx->state = state_previous
end sub

''
sub LISP_LEXER.settext( byref text as const string ) 

	ctx->state->buffer = text
	ctx->state->index0 = 0
	ctx->state->index1 = 0

	ctx->state->token = ""

end sub

''
function LISP_LEXER.gettoken( ) as LISP_TOKEN_ID
	function = ctx->state->gettoken()
end function

''
function LISP_LEXER.token() as zstring ptr
	function = strptr( ctx->state->token )
end function

''
function LISP_LEXER.filename() as string
	function = ctx->state->filename
end function

''
sub LISP_LEXER.setfile( byref f as const string ) 
	ctx->state->filename = f
end sub

''
function LISP_LEXER.lineno() as integer
	function = ctx->state->lineno
end function

''
function LISP_LEXER.column() as integer
	function = ctx->state->column
end function

end namespace
