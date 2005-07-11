/*
 * Amiga MUD
 *
 * Copyright (c) 1998 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

typedef enum {
    bc_error,		/* catch problems */
    bc_ret, 		/* return void from subroutine */
    bc_ret1,		/* return a value from subroutine */
    bc_spDec,		/* add space to stack for locals */
    bc_bi,		/* call builtin */
    bc_bi01,		/* call builtin, 0 parms, with result */
    bc_BI01,		/* direct call to one of them */
    bc_bi10,		/* call builtin, 1 parm, no string frees */
    bc_BI10,		/* direct call to builtin with 1 parm */
    bc_bi31,		/* needed for 'SubString' */
    bc_BI31,
    bc_call,		/* static call, via key, turns into one of: */
    bc_JSR, 		/* direct call to other byte-code */
    bc_CALL,		/* call to tree interpreted code */
    bc_pshL,		/* push local variable/parameter */
    bc_pshLs,		/* one-byte offset */
    bc_pshL0,		/* offset = 0 */
    bc_pshL4,		/* offset = 4 */
    bc_pshL8,		/* offset = 8 */
    bc_popL,		/* pop into local variable/parameter */
    bc_popLs,		/* one-byte offset */
    bc_popL0,		/* offset = 0 */
    bc_popL4,		/* offset = 4 */
    bc_popL8,		/* offset = 8 */
    bc_popS,		/* pop into local string variable/parameter */
    bc_popSs,		/* one-byte offset */
    bc_initL,		/* put null string into local variable */
    bc_freeL,		/* free string in local/parameter */
    bc_pshC,		/* push constant value */
    bc_pshZ,		/* push the constant zero */
    bc_pshCL,		/* push sign extended byte constant */
    bc_pshCH,		/* push constant which is zero except for hi */
    bc_psh1,		/* push the constant 1 */
    bc_pshS,		/* push string constant */
    bc_pshR,		/* push some reference */
    bc_ign, 		/* discard top stack element */
    bc_dup, 		/* duplicate top stack element */
    bc_add, 		/* int/fixed add */
    bc_add1,		/* int add of 1 */
    bc_sub, 		/* int/fixed sub */
    bc_sub1,		/* int sub of 1 */
    bc_iMul,		/* int multiplication */
    bc_iDiv,		/* int division */
    bc_iRem,		/* int modulo */
    bc_shl, 		/* int left shift */
    bc_shr, 		/* int right shift */
    bc_neg, 		/* signed int negate */
    bc_not, 		/* bitwise not */
    bc_and, 		/* bitwise int AND */
    bc_ior, 		/* bitwise int inclusive OR */
    bc_xor, 		/* bitwise int exclusive OR */
    bc_fMul,		/* fixed multiplication */
    bc_fDiv,		/* fixed division */
    bc_sFree,		/* pop and free a string */
    bc_sDup,		/* duplicate a string */
    bc_sCat,		/* string concatenation */
    bc_iLT, 		/* integer less than */
    bc_iLE, 		/* integer less than or equal */
    bc_iEQ, 		/* integer equality (also other) */
    bc_iNE, 		/* integer non-equality (also other) */
    bc_iGE, 		/* integer greater than or equal */
    bc_iGT, 		/* integer greater than */
    bc_sEQ, 		/* string equality */
    bc_sEQ00,		/* same, but no operand free */
    bc_sEQ01,		/* same, but no free of left operand */
    bc_sEQ10,		/* same, but no free of right operand */
    bc_sNE, 		/* string non-equality */
    bc_sNE00,
    bc_sNE01,
    bc_sNE10,
    bc_sLT, 		/* string less than */
    bc_sGT, 		/* string greater than */
    bc_sLE, 		/* string less than or equal */
    bc_sGE, 		/* string greater than or equal */
    bc_sEE, 		/* string equality, ignoring case */
    bc_sEE00,		/* same, but no operand free */
    bc_sEE01,		/* same, but no free of left operand */
    bc_sEE10,		/* same, but no free of right operand */
    bc_bNot,		/* boolean not */
    bc_bf,		/* forward long unconditional branch */
    bc_bft, 		/* forward long branch on true */
    bc_bff, 		/* forward long branch on false */
    bc_bb,		/* backward long unconditional branch */
    bc_bbt, 		/* backward long branch on true */
    bc_bbf, 		/* backward long branch on false */
    bc_bbts,		/* short backwards branch on true */
    bc_bbfs,		/* short backwards branch on false */
    bc_getProp,		/* get a property from a thing */
    bc_addProp,		/* add a property to a thing */
    bc_addPrpS,		/* Quick one for strings */
    bc_delProp,		/* remove a property from a thing */
    bc_getIEl,		/* get int element */
    bc_getFEl,		/* get fixed element */
    bc_getTEl,		/* get thing element */
    bc_getAEl,		/* get action element */
    bc_putIEl,		/* put int element */
    bc_putFEl,		/* put fixed element */
    bc_putTEl,		/* put thing element */
    bc_putAEl,		/* put action element */
    bc_caseI,		/* direct indexed case */
    bc_caseS,		/* binary search case */
} BcCode_t;
