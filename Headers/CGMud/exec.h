/*
 * Amiga MUD
 *
 * Copyright (c) 1997 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

/* exec.h - types and structures used to internally represent executables */

#define EXEC_H

enum {				/* order is in decreasing precedence */
    ex_null,
    ex_byteCode,
    ex_error,
    ex_empty,
    ex_intRef,
    ex_fixedRef,
    ex_procRef,
    ex_thingRef,
    ex_grammarRef,
    ex_playerRef,
    ex_propRef,
    ex_tableRef,
    ex_local,
    ex_string,
    ex_int,
    ex_fixed,
    ex_bool,
    ex_status,
    ex_nil,
    ex_ts,
    ex_if,
    ex_while,
    ex_for,
    ex_case,
    ex_ignore,
    ex_ignoreS,
    ex_builtinCall,
    ex_knownCall,
    ex_unknownCall,
    ex_note,
    ex_getBoolProp,		/* order corresponds to types order */
    ex_getIntProp,
    ex_getFixedProp,
    ex_getThingProp,
    ex_getActionProp,
    ex_getStringProp,
    ex_getTableProp,
    ex_getGrammarProp,
    ex_getIntListProp,
    ex_getFixedListProp,
    ex_getThingListProp,
    ex_getActionListProp,
    ex_addBoolProp,		/* order corresponds to types order */
    ex_addIntProp,
    ex_addFixedProp,
    ex_addThingProp,
    ex_addActionProp,
    ex_addStringProp,
    ex_addTableProp,
    ex_addGrammarProp,
    ex_addIntListProp,
    ex_addFixedListProp,
    ex_addThingListProp,
    ex_addActionListProp,
    ex_delBoolProp,		/* order corresponds to types order */
    ex_delIntProp,
    ex_delFixedProp,
    ex_delThingProp,
    ex_delActionProp,
    ex_delStringProp,
    ex_delTableProp,
    ex_delGrammarProp,
    ex_delIntListProp,
    ex_delFixedListProp,
    ex_delThingListProp,
    ex_delActionListProp,
    ex_getIntElement,		/* order corresponds to types order */
    ex_getFixedElement,
    ex_getThingElement,
    ex_getActionElement,
    ex_putIntElement,		/* order corresponds to types order */
    ex_putFixedElement,
    ex_putThingElement,
    ex_putActionElement,

    ex_negate,

    ex_bitNot,

    ex_shiftLeft,		/* decreasing priority for binaries */
    ex_shiftRight,
    ex_bitAnd,
    ex_bitXor,

    ex_bitOr,

    ex_times,
    ex_divide,
    ex_remainder,

    ex_plus,
    ex_minus,

    ex_equal,
    ex_notEqual,
    ex_less,
    ex_greater,
    ex_lessOrEqual,
    ex_greaterOrEqual,

    ex_fNegate, 		/* decreasing priority for fixed binaries */

    ex_fTimes,
    ex_fDivide,

    ex_fPlus,
    ex_fMinus,

    ex_fEqual,
    ex_fNotEqual,
    ex_fLess,
    ex_fGreater,
    ex_fLessOrEqual,
    ex_fGreaterOrEqual,

    ex_strPlus,

    ex_strEqual,
    ex_strNotEqual,
    ex_strLess,
    ex_strGreater,
    ex_strLessOrEqual,
    ex_strGreaterOrEqual,
    ex_strEqualEqual,

    ex_logNot,

    ex_logAnd,

    ex_logOr,

    ex_assignment,
    ex_sequence
};
typedef unsigned char ExecKind_t;

struct Exec;

typedef struct IfList {
    struct IfList *ifl_next;
    struct Exec *ifl_condition;
    struct Exec *ifl_body;
} IfList_t;

typedef struct {
    IfList_t *if_alternatives;
    struct Exec *if_else;
} If_t;

typedef struct {
    struct Exec *wh_condition;
    struct Exec *wh_body;
} While_t;

typedef struct {
    LocalList_t *fo_variable;
    struct Exec *fo_start;
    struct Exec *fo_limit;
    struct Exec *fo_body;
} For_t;

typedef struct CaseIndexList {
    struct CaseIndexList *cil_next;
    struct Exec *cil_index;
} CaseIndexList_t;

typedef struct CaseList {
    struct CaseList *cal_next;
    CaseIndexList_t *cal_indexes;
    struct Exec *cal_body;
} CaseList_t;

typedef struct {
    struct Exec *ca_selector;
    CaseList_t *ca_alternatives;
    struct Exec *ca_default;
} Case_t;

typedef struct StatementSequence {
    struct StatementSequence *sts_next;
    struct Exec *sts_this;
} StatementSequence_t;

typedef struct ArgumentList {
    struct ArgumentList *al_next;
    struct Exec *al_this;
} ArgumentList_t;

typedef struct {
    Proc_t *bcl_proc;
    ULONG_T bcl_key;
    ArgumentList_t *bcl_arguments;
} BuiltinCall_t;

typedef struct {
    struct Exec *ucl_action;
    ArgumentList_t *ucl_arguments;
    UINT_T ucl_resultType;
} UserCall_t;

typedef struct {
    struct Exec *as_destination;
    struct Exec *as_source;
} Assignment_t;

typedef struct {
    struct Exec *ex_left;
    struct Exec *ex_right;
} Expression_t;

typedef struct {
    struct Exec *prg_thing;
    struct Exec *prg_property;
} PropGet_t;

typedef struct {
    struct Exec *pra_thing;
    struct Exec *pra_property;
    struct Exec *pra_value;
} PropAdd_t;

typedef struct {
    struct Exec *prd_thing;
    struct Exec *prd_property;
} PropDel_t;

typedef struct {
    struct Exec *elg_list;
    struct Exec *elg_index;
} ElemGet_t;

typedef struct {
    struct Exec *elp_list;
    struct Exec *elp_index;
    struct Exec *elp_value;
} ElemPut_t;

typedef struct Exec {
    ExecKind_t ex_kind;
    BYTE_T ex_intVal[3];
    union {
	If_t *ex_ifPtr;
	While_t *ex_whilePtr;
	For_t *ex_forPtr;
	Case_t *ex_casePtr;
	StatementSequence_t *ex_sequencePtr;
	BuiltinCall_t *ex_builtinCallPtr;
	UserCall_t *ex_userCallPtr;
	Assignment_t *ex_assignmentPtr;
	Expression_t *ex_expressionPtr;
	PropGet_t *ex_getPtr;
	PropAdd_t *ex_addPtr;
	PropDel_t *ex_delPtr;
	ElemGet_t *ex_elemGetPtr;
	ElemPut_t *ex_elemPutPtr;
	RefList_t *ex_refPtr;
	LocalList_t *ex_localPtr;
	char *ex_stringPtr;
	LONG_T ex_integer;
    } ex_v;
} Exec_t;
