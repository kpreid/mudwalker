/*
 * Amiga MUD
 *
 * Copyright (c) 1997 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

/*
 * MUDLibPrivate.h - additional routines in MUDLib, which are exported by
 *	the library, but only to other components of MUD written by me.
 */

#ifndef REQUEST_H
struct Request;
#endif

extern struct Request *allocRequestE(MUDState_t *ms, ULONG_T len);
extern void freeRequestE(MUDState_t *ms, struct Request *rq);
extern void requestInitE(MUDState_t *ms, ULONG_T rqLimit);
extern void requestTermE(MUDState_t *ms);

extern ULONG_T libInitE(MUDState_t *ms, ULONG_T memLimit, ULONG_T rqMax);
extern void libTermE(MUDState_t *ms);
extern void memFreeE(MUDState_t *ms, void *p, ULONG_T len);
extern void *memAllocE(MUDState_t *ms, ULONG_T len);
extern void *memAllocET(MUDState_t *ms, ULONG_T len, char *what);
extern void memRecoverE(MUDState_t *ms);
extern void dumpBlocksE(MUDState_t *ms, char *where);
extern void showBlocksE(MUDState_t *ms, char *where);
extern void memValidateE(MUDState_t *ms, char *where);

extern void symCreateE(MUDState_t *ms, Table_t *tb, ULONG_T shift);
extern void symDestroyE(MUDState_t *ms, Table_t *tb);
extern Entry_t *symEnterE(MUDState_t *ms, Table_t *tb,
			  char *name, ULONG_T nameLen);
extern Entry_t *symLookupE(Table_t *tb, char *name, ULONG_T nameLen);
extern void symDeleteE(MUDState_t *ms, Table_t *tb,
		       char *name, ULONG_T nameLen);
extern void *symReadE(MUDState_t *ms, Table_t *tb, void *b);
extern void symWriteE(MUDState_t *ms, Table_t *tb);

extern void writeResetE(MUDState_t *ms);
extern void writeByteE(MUDState_t *ms, BYTE_T b);
extern void writeWordE(MUDState_t *ms, UINT_T w);
extern void writeLongE(MUDState_t *ms, ULONG_T l);
extern void writeBytes(MUDState_t *ms, void *b, UINT_T l);
extern void writeStringE(MUDState_t *ms, CHAR_T *st);
extern void writeResultE(MUDState_t *ms, BYTE_T **pBytes, UINT_T *pLen);
extern ULONG_T readLongE(void *pb);

extern void writeProcE(MUDState_t *ms, Proc_t *pr);
extern Proc_t *readProcE(MUDState_t *ms, void *p);
extern void freeProcE(MUDState_t *ms, Proc_t *pr,
		      ULONG_T myKey, ULONG_T freeRefs);
extern void clearProcE(MUDState_t *ms, Proc_t *pr, ULONG_T mykey);
