#ifndef __LISP_CTX_BI__
#define __LISP_CTX_BI__

/'
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

#include "lisp.bi"

namespace LISP

	type LISP_LEXER_ as LISP_LEXER
	type LISP_PARSER_ as LISP_PARSER
	type LISP_OBJECTS_ as LISP_OBJECTS
	type LISP_FUNCTIONS_ as LISP_FUNCTIONS
	type LISP_EVAL_ as LISP_EVAL
	type LISP_OBJECT_ as LISP_OBJECT
	type LISP_FUNCTION_ as LISP_FUNCTION

	''
	type LISP_CTX

		declare constructor()
		declare destructor()

		lexer as LISP_LEXER_ ptr
		parser as LISP_PARSER_ ptr
		objects as LISP_OBJECTS_ ptr
		functions as LISP_FUNCTIONS_ ptr
		evaluator as LISP_EVAL_ ptr

		declare sub GarbageCollect()
		declare function GetErrorText() as string
		declare function Eval( byref text as const string ) as LISP_ERROR
		declare function Load( byref filename as const string ) as LISP_ERROR
				
		ErrorCode as LISP_ERROR
		ErrorText as string
		ErrorFile as string
		ErrorLine as integer
		ErrorColumn as integer
		
		declare sub ResetError( )
		declare sub RaiseError( byval e_code as LISP_ERROR, byref e_text as const string = "")
		declare sub RaiseWarning( byval e_code as LISP_ERROR, byref e_text as const string = "")

		EchoInput as boolean
		ShowResults as boolean
		print_cb as LISP_PRINT_CALLBACK

		declare sub PrintOut( byref s as const string )
		declare function Dump( byval args as LISP_OBJECT_ ptr ) as LISP_OBJECT_ ptr


	end type

end namespace

#endif
