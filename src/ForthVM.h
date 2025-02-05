// ForthVM.h
//
// Copyright (c) 1996--2019, Krishna Myneni
//   <krishna.myneni@ccreweb.org>
//
// This software is provided under the terms of the GNU
// Affero General Public License (AGPL), v3.0 or later.
//
#ifndef __FORTHVM_H__
#define __FORTHVM_H__

#define MAX_V_ERR_MESSAGES 23

// Virtual machine error codes

#define E_V_NOERROR         0
#define E_V_NOTADDR         1
#define E_V_NOTIVAL         2
#define E_V_BADTYPE         3
#define E_V_DIV_ZERO        4
#define E_V_RET_STK_CORRUPT 5
#define E_V_BADCODE         6
#define E_V_STK_UNDERFLOW   7
#define E_V_QUIT            8
#define E_V_REALLOT         9
#define E_V_CREATE         10
#define E_V_NO_EOS         11
#define E_V_NO_DO          12
#define E_V_NO_BEGIN       13
#define E_V_ELSE_NO_IF     14
#define E_V_THEN_NO_IF     15
#define E_V_ENDOF_NO_OF    16
#define E_V_NO_CASE        17
#define E_V_OPENFILE       18
#define E_V_BADSTACKADDR   19
#define E_V_DIV_OVERFLOW   20
#define E_V_DBL_OVERFLOW   21
#define E_V_COMPILE_ONLY   22

#define DEFAULT_OUTPUT_FILENAME "kforth.out"

int InitSystemVars ();
int NullSystemVars ();
int OpenForth ();
void CloseForth ();
bool InStringTable (char*);
void RemoveLastWord ();
vector<WordListEntry>::iterator LocateWord (char*);
vector<WordListEntry>::iterator LocateCfa  (void*);
void ClearControlStacks ();
void OpsCopyInt (long int, long int);
void OpsPushInt (long int);
void OpsPushTwoInt (long int, long int);
void OpsPushDouble (double);
int OpsCompileByte ();
int OpsCompileInt ();
int OpsCompileDouble ();
void PrintVM_Error (long int);
int ForthVM (vector<byte>*, long int**, byte**);

// The following C++ functions have C linkage

extern "C" {
int CPP_wordlist();
int CPP_forthwordlist();
int CPP_getcurrent();
int CPP_setcurrent();
int CPP_setorder();
int CPP_getorder();
int CPP_searchwordlist();
int CPP_definitions();
int CPP_vocabulary();
int CPP_only();
int CPP_also();
int CPP_previous();
int CPP_order();
int CPP_forth();
int CPP_assembler();
int CPP_traverse_wordlist();
int CPP_name_to_string();
int CPP_name_to_interpret();
int CPP_colon();
int CPP_semicolon();
int CPP_compilename();
int CPP_lparen();
int CPP_dotparen();
int CPP_tick();
int CPP_tobody();
int CPP_defined();
int CPP_undefined();
int CPP_find();
int CPP_dot();
int CPP_dotr();
int CPP_udot0();
int CPP_udot();
int CPP_udotr();
int CPP_ddot();
int CPP_fdot();
int CPP_fsdot();
int CPP_dots();
int CPP_emit();
int CPP_cr();
int CPP_spaces();
int CPP_type();
int CPP_allocate();
int CPP_free();
int CPP_resize();
int CPP_allot();
int CPP_queryallot();
int CPP_words();
int CPP_create();
int CPP_alias();
int CPP_variable();
int CPP_twovariable();
int CPP_fvariable();
int CPP_constant();
int CPP_twoconstant();
int CPP_fconstant();
int CPP_char();
int CPP_bracketchar();
int CPP_brackettick();
int CPP_myname();
int CPP_compilecomma();
int CPP_bracketcompile();
int CPP_postpone();
int CPP_literal();
int CPP_twoliteral();
int CPP_sliteral();
int CPP_fliteral();
int CPP_cquote();
int CPP_squote();
int CPP_dotquote();
int CPP_forget();
int CPP_cold();
int CPP_bye();
int CPP_tofile();
int CPP_console();
int CPP_do();
int CPP_querydo();
int CPP_leave();
int CPP_abortquote();
int CPP_begin();
int CPP_while();
int CPP_repeat();
int CPP_until();
int CPP_again();
int CPP_if();
int CPP_else();
int CPP_then();
int CPP_case();
int CPP_endcase();
int CPP_of();
int CPP_endof();
int CPP_recurse();
int CPP_does();
int CPP_immediate();
int CPP_nondeferred();
int CPP_evaluate();
int CPP_included();
int CPP_include();
int CPP_source();
int CPP_refill();
int CPP_state();
int CPP_spstore();
int CPP_rpstore();
}
#endif

