/*
 * Amiga MUD
 *
 * Copyright (c) 1997 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

#define TYPES_H

#define TYPE_ERROR		0				/* 00 */
#define TYPE_VOID		(TYPE_ERROR + 1)		/* 01 */
#define TYPE_NIL		(TYPE_VOID + 1) 		/* 02 */
#define TYPE_STATUS		(TYPE_NIL + 1)			/* 03 */
#define TYPE_PLAYER		(TYPE_STATUS + 1)		/* 04 */

/* NOTE: the following group is set up so that the base types are
   in the same sequence as the corresponding property types and
   list element types. This also maps directly onto the ex_ codes. */

#define TYPE_BOOLEAN		(TYPE_PLAYER + 1)		/* 05 */
#define TYPE_INTEGER		(TYPE_BOOLEAN + 1)		/* 06 */
#define TYPE_FIXED		(TYPE_INTEGER + 1)		/* 07 */
#define TYPE_THING		(TYPE_FIXED + 1)		/* 08 */
#define TYPE_ACTION		(TYPE_THING + 1)		/* 09 */
#define TYPE_STRING		(TYPE_ACTION + 1)		/* 0a */
#define TYPE_TABLE		(TYPE_STRING + 1)		/* 0b */
#define TYPE_GRAMMAR		(TYPE_TABLE + 1)		/* 0c */

#define TYPE_LIST_INTEGER	(TYPE_GRAMMAR + 1)		/* 0d */
#define TYPE_LIST_FIXED 	(TYPE_LIST_INTEGER + 1) 	/* 0e */
#define TYPE_LIST_THING 	(TYPE_LIST_FIXED + 1)		/* 0f */
#define TYPE_LIST_ACTION	(TYPE_LIST_THING + 1)		/* 10 */

#define TYPE_PROP_BOOLEAN	(TYPE_LIST_ACTION + 1)		/* 11 */
#define TYPE_PROP_INTEGER	(TYPE_PROP_BOOLEAN + 1) 	/* 12 */
#define TYPE_PROP_FIXED 	(TYPE_PROP_INTEGER + 1) 	/* 13 */
#define TYPE_PROP_THING 	(TYPE_PROP_FIXED + 1)		/* 14 */
#define TYPE_PROP_ACTION	(TYPE_PROP_THING + 1)		/* 15 */
#define TYPE_PROP_STRING	(TYPE_PROP_ACTION + 1)		/* 16 */
#define TYPE_PROP_TABLE 	(TYPE_PROP_STRING + 1)		/* 17 */
#define TYPE_PROP_GRAMMAR	(TYPE_PROP_TABLE + 1)		/* 18 */

#define TYPE_PROP_LIST_INTEGER	(TYPE_PROP_GRAMMAR + 1) 	/* 19 */
#define TYPE_PROP_LIST_FIXED	(TYPE_PROP_LIST_INTEGER + 1)	/* 1a */
#define TYPE_PROP_LIST_THING	(TYPE_PROP_LIST_FIXED + 1)	/* 1b */
#define TYPE_PROP_LIST_ACTION	(TYPE_PROP_LIST_THING + 1)	/* 1c */

/* the rest are for internal use only */

#define TYPE_LIST_ANY		(TYPE_PROP_LIST_ACTION + 1)	/* 1d */
#define TYPE_ELEMENT		(TYPE_LIST_ANY + 1)		/* 1e */
#define TYPE_THING_STATUS	(TYPE_ELEMENT + 1)		/* 1f */
#define TYPE_MACHINE		(TYPE_THING_STATUS + 1) 	/* 20 */

#define TYPE_LAST		TYPE_MACHINE

#define TYPE_MASK	0xfc000000
#define INDEX_MASK	0x03ffffff

#define TYPE_SHIFT	26

#define W_WORD		0x3f
#define W_SYNONYM	0x3e
#define W_VERBTAIL	0x3d
#define W_VERB		0x3c

#define NIL_NIL 		(TYPE_NIL		<< TYPE_SHIFT)
#define NIL_PLAYER		(TYPE_PLAYER		<< TYPE_SHIFT)
#define NIL_THING		(TYPE_THING		<< TYPE_SHIFT)
#define NIL_ACTION		(TYPE_ACTION		<< TYPE_SHIFT)
#define NIL_TABLE		(TYPE_TABLE		<< TYPE_SHIFT)
#define NIL_GRAMMAR		(TYPE_GRAMMAR		<< TYPE_SHIFT)
#define NIL_LIST_INTEGER	(TYPE_LIST_INTEGER	<< TYPE_SHIFT)
#define NIL_LIST_FIXED		(TYPE_LIST_FIXED	<< TYPE_SHIFT)
#define NIL_LIST_THING		(TYPE_LIST_THING	<< TYPE_SHIFT)
#define NIL_LIST_ACTION 	(TYPE_LIST_ACTION	<< TYPE_SHIFT)
#define NIL_PROP_BOOLEAN	(TYPE_PROP_BOOLEAN	<< TYPE_SHIFT)
#define NIL_PROP_INTEGER	(TYPE_PROP_INTEGER	<< TYPE_SHIFT)
#define NIL_PROP_FIXED		(TYPE_PROP_FIXED	<< TYPE_SHIFT)
#define NIL_PROP_THING		(TYPE_PROP_THING	<< TYPE_SHIFT)
#define NIL_PROP_ACTION 	(TYPE_PROP_ACTION	<< TYPE_SHIFT)
#define NIL_PROP_STRING 	(TYPE_PROP_STRING	<< TYPE_SHIFT)
#define NIL_PROP_TABLE		(TYPE_PROP_TABLE	<< TYPE_SHIFT)
#define NIL_PROP_GRAMMAR	(TYPE_PROP_GRAMMAR	<< TYPE_SHIFT)
#define NIL_PROP_LIST_INTEGER	(TYPE_PROP_LIST_INTEGER << TYPE_SHIFT)
#define NIL_PROP_LIST_FIXED	(TYPE_PROP_LIST_FIXED	<< TYPE_SHIFT)
#define NIL_PROP_LIST_THING	(TYPE_PROP_LIST_THING	<< TYPE_SHIFT)
#define NIL_PROP_LIST_ACTION	(TYPE_PROP_LIST_ACTION	<< TYPE_SHIFT)

#define NIL_MACHINE		(TYPE_MACHINE		<< TYPE_SHIFT)

#define PUBLIC_TABLE_KEY	(NIL_TABLE | 1)
#define NAME_KEY		(NIL_PROP_STRING | 2)
#define SYSADMIN_KEY		(NIL_PLAYER | 5)
#define ICON_KEY		(NIL_PROP_LIST_INTEGER | 0xc)

#define EN_EMPTY		0		/* slot never been used */
#define EN_FREE 		0xffff		/* slot now empty */

#define NAME_MAP_SIZE		32

struct Exec;

typedef struct {
    ULONG_T en_hash;		/* hash function value of name */
    CHAR_T *en_name;		/* pointer to buffer holding the name */
    ULONG_T en_key;		/* the key which is the value of this symbol */
    UINT_T en_nameLen;		/* length in bytes of name - including \e */
    UINT_T en_XXX;		/* pad to 4 byte boundary */
} Entry_t;

typedef struct {
    ULONG_T tb_owner;		/* owner of this table */
    Entry_t *tb_entries;	/* pointer to actual entry array */
    UINT_T tb_useCount; 	/* number of references to it */
    UINT_T tb_entryCount;	/* number of actual entries in table */
    UINT_T tb_usedCount;	/* number of entries in use now */
    UINT_T tb_shift;		/* shift to multiply by entryCount */
    UINT_T tb_mask;		/* mask to modulo by entryCount */
    BOOL_T tb_dirty;		/* any changes made to it */
} Table_t;

typedef struct {
    Entry_t *(nm_map[NAME_MAP_SIZE]);
    Table_t *nm_table;
} NameMap_t;

enum {
    ps_normal,
    ps_apprentice,
    ps_wizard
};
typedef unsigned char PlayerStatus_t;

typedef struct {
    CHAR_T pl_password[PASSWORD_LEN];
    ULONG_T pl_key;
    ULONG_T pl_symbolTableKey;
    ULONG_T pl_sponsor;
    ULONG_T pl_location;
    ULONG_T pl_inputAction;
    ULONG_T pl_rawKeyAction;
    ULONG_T pl_mouseDownAction;
    ULONG_T pl_buttonAction;
    ULONG_T pl_promptKey;
    ULONG_T pl_lastOn;
    ULONG_T pl_logonCount;
    ULONG_T pl_totalSeconds;
    ULONG_T pl_idleAction;
    ULONG_T pl_activeAction;
    ULONG_T pl_effectDoneAction;
    UINT_T pl_textWidth;
    UINT_T pl_textHeight;
    UINT_T pl_flags;
    PlayerStatus_t pl_status;
    BOOL_T pl_wizardMode;
    BOOL_T pl_newPlayer;
} Player_t;

typedef struct LocalList {
    struct LocalList *ll_next;
    CHAR_T *ll_name;
    UINT_T ll_type;
    UINT_T ll_offset;
} LocalList_t;

typedef struct RefList {
    struct RefList *rl_next;
    CHAR_T *rl_name;			/* may be nil if not found yet */
    ULONG_T rl_key;
} RefList_t;

typedef ULONG_T (*Comp_t)(void);

typedef struct Proc {
    LocalList_t *pr_parameters;
    LocalList_t *pr_locals;
    RefList_t *pr_refs;
    struct Exec *pr_body;
    Comp_t pr_compiled;
    BYTE_T *pr_byteCode;
    ULONG_T pr_owner;
    UINT_T pr_resultType;
    UINT_T pr_localCount;		/* # bytes of local vars + pars */
    UINT_T pr_useCount;
    UINT_T pr_byteCodeLen;
    BOOL_T pr_utility;			/* do not setuid when run */
    BOOL_T pr_wizard;			/* not runnable by apprentices */
    BOOL_T pr_public;			/* visible to all */
    BOOL_T pr_isCompiled;
    BOOL_T pr_stripped;
    BOOL_T pr_locked;			/* an in-memory thing only */
    BOOL_T pr_byteSwapped;		/* an in-memory thing only */
    PlayerStatus_t pr_ownerStatus;
} Proc_t;

enum {
    ts_private,
    ts_readonly,
    ts_wizard,
    ts_public
};
typedef unsigned char ThingStatus_t;

typedef struct {
    ULONG_T th_parent;
    ULONG_T th_owner;
    UINT_T th_useCount;
    BYTE_T th_propCount;		/* number of elements on list */
    ThingStatus_t th_status;
} Thing_t;

typedef struct {
    ULONG_T prp_owner;
    UINT_T prp_useCount;
    UINT_T prp_XXX;			/* pad to multiple of 4 bytes */
} Property_t;

typedef struct {
    ULONG_T at_prop;
    ULONG_T at_value;
} Attr_t;

typedef struct {
    ULONG_T l_owner;
    UINT_T l_useCount;
    UINT_T l_elementCount;
} ItemList_t;

typedef union {
    Proc_t *qv_proc;
    CHAR_T *qv_string;
    LONG_T qv_integer;
} QValue_t;

typedef struct {
    ULONG_T mch_owner;
    ULONG_T mch_key;			/* key of associated thing */
    ULONG_T mch_location;		/* same as for player */
    ULONG_T mch_sayProc;		/* when someone talks */
    ULONG_T mch_whisperMeProc;		/* someone whispers to machine */
    ULONG_T mch_whisperOtherProc;	/* overhears some other whisper */
    ULONG_T mch_pageProc;		/* someone pages the machine */
    ULONG_T mch_poseProc;		/* someone does a pose */
    ULONG_T mch_otherProc;		/* an 'OPrint'/'ABPrint' is done */
    ULONG_T mch_idleProc;		/* dungeon goes idle */
    ULONG_T mch_activeProc;		/* dungeon back from idle */
    UINT_T mch_useCount;		/* these can be destroyed */
    UINT_T mch_XXX;			/* pad to 4 byte boundary */
} Machine_t;

enum {
    vt_noObj,				/* just the verb */
    vt_dirObj,				/* verb and a direct object */
    vt_twoObj				/* direct and indirect objects */
};
typedef unsigned char VerbType_t;

typedef struct Alternative {
    struct Alternative *alt_next;	/* next alternative, this verb */
    ULONG_T alt_action; 		/* proc to call */
    UINT_T alt_separator;		/* separator/preposition word */
    VerbType_t alt_type;		/* what type of verb */
} Alternative_t;

typedef struct WordList {
    struct WordList *wl_next;
    CHAR_T *wl_word;			/* points directly at table one */
    ULONG_T wl_code;			/* word code for this word */
    ULONG_T wl_key;			/* database key of entry */
    union {
	ULONG_T wl_action;		/* key of proc to call when parsing */
	struct WordList *wl_synonym;	/* points to another entry */
	Alternative_t *wl_alternatives; /* for VERBX */
    } wl_;
    UINT_T wl_refCount; 		/* for synonym references */
    UINT_T wl_separator;		/* code of the separator */
} WordList_t;

typedef struct {
    Table_t g_words;
    WordList_t *g_wordList;
    ULONG_T g_nextCode;
} Grammar_t;

typedef struct {
    ULONG_T int_value;
    UINT_T int_owner;
    UINT_T int_useCount;
} Integer_t;

#define BC_STACK_EXTRA		(2 * sizeof(ULONG_T))

#define PL_PROMPT_ON		0x0001

#define BOOLEAN_FALSE		(ULONG_T) 0
#define BOOLEAN_TRUE		(ULONG_T) 1

#define STATUS_SUCCEED		(ULONG_T) 1
#define STATUS_FAIL		(ULONG_T) 2
#define STATUS_CONTINUE 	(ULONG_T) 3

#define TABLE_PUBLIC		(TYPE_TABLE << TYPE_SHIFT | 0x00ffffff)
#define TABLE_PRIVATE		(TYPE_TABLE << TYPE_SHIFT | 0x00fffffe)
