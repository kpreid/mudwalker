/*
 * Amiga MUD
 *
 * Copyright (c) 1997 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

#define REQUEST_H

enum {
    rt_first,
    rt_killClient,		/* request that client go away */
    rt_nukeClient,		/* demand that client exit immediately */
    rt_3,
    rt_4,
    rt_5,
    rt_6,
    rt_7,
    rt_8,
    rt_9,
    rt_10,
    rt_11,
    rt_12,
    rt_13,
    rt_14,
    rt_15,
    rt_16,
    rt_17,
    rt_18,
    rt_19,
    rt_20,
    rt_startClient,		/* startup up a new client */
    rt_stopClient,		/* shut down this client */
    rt_beginClient,		/* client is doing a real run */
    rt_endClient,		/* a player is done - close him off */
    rt_manyOtherTypesWhichArePrivate
};
typedef unsigned char RequestType_t;

typedef struct Request {
    struct Request *rq_next;		/* next in any list */
    struct Request *rq_prev;
    ULONG_T rq_key;			/* [longword] used internally */
    ULONG_T rq_timeStamp;
    UINT_T rq_clientId; 		/* [word] which client this is */
    UINT_T rq_availLen; 		/* [word] space available in request */
    UINT_T rq_usedLen;			/* [word] space used in this request */
    RequestType_t rq_type;		/* [byte] what kind of request it is */
    BOOL_T rq_flag;			/* [byte] used for various things */
    BYTE_T ru_bytes[TEXT_LENGTH];	/* private stuff for the request */
} Request_t;

#define REQ_LEN (sizeof(Request_t) - 2 * sizeof(Request_t *) - TEXT_LENGTH)
