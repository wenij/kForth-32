// kForth.cpp
//
// The kForth environment
//
// Copyright (c) 1998--2019 Krishna Myneni, 
//   <krishna.myneni@ccreweb.org>
// 
// This software is provided under the terms of the GNU 
// Affero General Public License (AGPL), v 3.0 or later.
//
// Contributions by (source code, bug fixes, documentation, 
// packaging, misc):
//
//    David P. Wallace          input line history, default directory, cygwin
//                                port, misc.
//    Matthias Urlichs          maintains Debian package
//    Guido Draheim             maintains RPM packages
//    Brad Knotwell             interpreter Ctrl-D handling and dictionary
//                                initialization.
//    Alaric B. Snell           command line parsing
//    Todd Nathan               ported kForth to BeOS
//    Bdale Garbee              created Debian kForth package
//    Christopher M. Brannon    bug alert for default-directory handling
//    David N. Williams         Mac OS X ppc engine port, a few new words
//
// Usage from console prompt:
//
//      kforth [name[.4th]] [-D] [-e string]
//
#ifdef VERSION
const char* version=VERSION;
#else
const char* version="?";
#endif
const char* build=BUILD_DATE;

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
using std::istream;
using std::ostream;
using std::cout;
using std::endl;
using std::istringstream;
using std::ostringstream;
using std::vector;
extern "C" {
#include <stdio.h>
#include <stdlib.h>
#include <readline/readline.h>
#include <readline/history.h>
}
#include "fbc.h"
#include "ForthCompiler.h"
#include "ForthVM.h"

extern vector<WordList> Dictionary;
extern char* C_ErrorMessages[];

extern "C" long int* JumpTable;
extern "C" long int* BottomOfStack;
extern "C" long int* BottomOfReturnStack;
extern "C" char TIB[];
extern "C" {
    void echo_on(void);
    void echo_off(void);
}

int debug = 0;

int main(int argc, char *argv[])
{
    ostringstream initial_commands (ostringstream::out);
    istringstream* pSS = NULL;
    const char* prompt = " ok\n";
    int nWords = OpenForth();

    if (argc < 2) {
	cout << "kForth-32 v " << version << "\t (Build: " << build << ")" << endl;
	cout << "Copyright (c) 1998--2019 Krishna Myneni" << endl;
        cout << "Contributions by: dpw gd mu bk abs tn cmb bg dnw" << endl;
	cout << "Provided under the GNU Affero General Public License, v3.0 or later" 
	  << endl << endl;
    }
    else {
    	int i = 1;

	while (i < argc) {
	  if (!strcmp(argv[i], "-D")) {
	    debug = -1;
	  }
	  else if (!strcmp(argv[i], "-e")) {
	    if (argc > i) {
	      initial_commands << argv[i+1] << endl; 
	    }
	    ++i;
	  }
	  else {
	    initial_commands << "include " << argv[i] << endl;
	  }
	  ++i;
        }
        pSS = new istringstream(initial_commands.str());
    }

    if (debug) {
	cout << '\n' << nWords << " words defined.\n";
	cout << "Jump Table address:  " << &JumpTable << endl;
	cout << "Bottom of Stack:     " << BottomOfStack << endl;
	cout << "Bottom of Ret Stack: " << BottomOfReturnStack << endl;
    }
    if ( ! pSS) cout << "\nReady!\n";

//----------------  the interpreter main loop

    SetForthOutputStream (cout);

    char s[256], *input_line;
    long int line_num = 0, ec = 0;
    vector<byte> op;

    while (1) {
        // Obtain commands and execute
        do {
	    if (! pSS) {
		if ((input_line = readline(NULL)) == NULL) CPP_bye();
		if (strlen(input_line)) add_history(input_line);
		strncpy(s, input_line, 255);
		free(input_line);
	       
            	pSS = new istringstream(s);
	    }
	    SetForthInputStream (*pSS);
	    echo_off();
            ec = ForthCompiler (&op, &line_num);
	    echo_on();
	    delete pSS;
	    pSS = NULL;

        } while (ec == E_C_ENDOFSTREAM) ;   // test for premature end of input
                                            //   that spans multiple lines
        if (ec) {
	    cout << "Line " << line_num << ": "; PrintVM_Error(ec);
	    cout << TIB << endl;
        }
	else
	    cout << prompt;
        op.erase(op.begin(), op.end());
    }
}
//---------------------------------------------------------------

