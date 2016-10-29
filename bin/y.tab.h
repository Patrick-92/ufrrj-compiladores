/* A Bison parser, made by GNU Bison 3.0.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2013 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_BIN_Y_TAB_H_INCLUDED
# define YY_YY_BIN_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    TK_PARAM = 258,
    TK_NUM = 259,
    TK_CHAR = 260,
    TK_BOOL = 261,
    TK_MAIN = 262,
    TK_ID = 263,
    TK_INT_TYPE = 264,
    TK_FLOAT_TYPE = 265,
    TK_CHAR_TYPE = 266,
    TK_DOUBLE_TYPE = 267,
    TK_LONG_TYPE = 268,
    TK_STRING_TYPE = 269,
    TK_BOOL_TYPE = 270,
    TK_FIM = 271,
    TK_ERROR = 272,
    TK_BREAK = 273,
    TK_AND = 274,
    TK_OR = 275,
    TK_NOT = 276,
    TK_GTE = 277,
    TK_LTE = 278,
    TK_DIFFERENCE = 279,
    TK_EQUAL = 280
  };
#endif
/* Tokens.  */
#define TK_PARAM 258
#define TK_NUM 259
#define TK_CHAR 260
#define TK_BOOL 261
#define TK_MAIN 262
#define TK_ID 263
#define TK_INT_TYPE 264
#define TK_FLOAT_TYPE 265
#define TK_CHAR_TYPE 266
#define TK_DOUBLE_TYPE 267
#define TK_LONG_TYPE 268
#define TK_STRING_TYPE 269
#define TK_BOOL_TYPE 270
#define TK_FIM 271
#define TK_ERROR 272
#define TK_BREAK 273
#define TK_AND 274
#define TK_OR 275
#define TK_NOT 276
#define TK_GTE 277
#define TK_LTE 278
#define TK_DIFFERENCE 279
#define TK_EQUAL 280

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_BIN_Y_TAB_H_INCLUDED  */
