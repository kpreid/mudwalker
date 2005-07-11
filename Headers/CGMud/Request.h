/*
 * Amiga MUD
 *
 * Copyright (c) 1997 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

#define REQUEST_H

enum {
    rt_first,			/* not used - marks the first one */

    /* server to client - no direct reply needed */

    rt_killClient,		/* request that client go away */
    rt_nukeClient,		/* demand that client exit immediately */
    rt_runClient,		/* tell client to go ahead with session */
    rt_message, 		/* text message from server to client */
    rt_enterWizardMode, 	/* enter wizard mode */
    rt_leaveWizardMode, 	/* leave wizard mode */
    rt_setContinue,		/* set error continue (server -> client) */
    rt_changePassword,		/* get client to read a password */
    rt_setPrompt,		/* set a new prompt in the client */
    rt_deleteProc,		/* ask client to delete proc from list */
    rt_effects, 		/* a bufferfull of effects to do */
    rt_editString,		/* a string to edit */
    rt_editProc,		/* a proc to edit */
    rt_getString,		/* request a string from client */
    rt_flushSymbol,		/* flush symbol from local cache */
    rt_defineEffect,		/* define the given effect */
    rt_queryFile,		/* ask if a file exists */

    /* client to server - direct reply needed */

    rt_shutDown,		/* shut down the server */
    rt_flush,			/* flush to disk */
    rt_syncShutDown,		/* shutdown, reply when all closed */
    rt_beginClient,		/* client is doing a real run */
    rt_endClient,		/* a player is done - close him off */
    rt_askPlayer,		/* check on the given player name */
    rt_creationCheck,		/* verify creation password */
    rt_createPlayer,		/* password, etc. OK - create new player */
    rt_loginPlayer,		/* password for existing player */
    rt_lookup,			/* look up a symbol */
    rt_findName,		/* find any name for this key */
    rt_readProc,		/* read the indicated proc */
    rt_writeProcNew,		/* write a new proc */
    rt_runProc, 		/* run this proc please */

    /* client to server - no direct reply needed */

    rt_log,			/* write this to log file */
    rt_inputLine,		/* input line from client to server */
    rt_setSync, 		/* control echo of rt_inputLine messages */
    rt_rawKey,			/* a raw key hit from client to server */
    rt_regionSelect,		/* a mouse-up event from client to server */
    rt_buttonHit,		/* a button-hit from client to server */
    rt_flushEffect,		/* ask/OK to flush the indicated effect */
    rt_textResize,		/* user has resized text window */
    rt_incRef,			/* increment ref count to given key */
    rt_decRef,			/* decrement ref count to given key */
    rt_symbolEnter,		/* define a symbol */
    rt_symbolDelete,		/* undefine a symbol */
    rt_useTable,		/* add a table to the use list */
    rt_unuseTable,		/* remove a table from the use list */
    rt_describeBuiltin, 	/* describe the indicated builtin proc */
    rt_describe,		/* carefully try to describe the given key */
    rt_graphicsFlip,		/* graphics on/off */
    rt_voiceFlip,		/* voice on/off */
    rt_soundFlip,		/* sound on/off */
    rt_musicFlip,		/* music on/off */
    rt_doEditProc,		/* please edit this proc */
    rt_editStringDone,		/* here is the final string */
    rt_replaceProc,		/* replace the indicated proc */
    rt_editProcDone,		/* just to notify */
    rt_getStringDone,		/* go the requested string */
    rt_effectDone,		/* a non-immediate effect has completed */
    rt_queryFileDone,		/* answer to file query */
    rt_createContainer,
    rt_createComponent,
    rt_makeFrame,

    rt_illegal			/* last request type - not legal */
};
typedef unsigned char RequestType_t;

typedef struct Request {
    struct Request *rq_next;
    struct Request *rq_prev;
    UINT_T rq_availLen;
    UINT_T rq_usedLen;
    ULONG_T rq_key;
#if TIME_STAMP
    ULONG_T rq_timeStamp;
#endif
    RequestType_t rq_type;
    BOOL_T rq_flag;		/* a handy flag for whatever */
    UINT_T rq_uint;		/* a handy uint for whatever */
    union {
	ULONG_T ru_otherKey;
	struct Request *ru_next;
	UINT_T ru_ints[TEXT_LENGTH / sizeof(UINT_T)];
	char ru_text[TEXT_LENGTH];
	BYTE_T ru_bytes[TEXT_LENGTH];
    } rq_u;
} Request_t;

#define REQ_LEN (sizeof(Request_t) - 2 * sizeof(Request_t *) - \
		 sizeof(UINT_T) - TEXT_LENGTH)
