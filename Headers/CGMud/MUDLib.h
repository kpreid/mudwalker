/*
 * Amiga MUD
 *
 * Copyright (c) 1997 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

/*
 * MUDLib.h - routines, etc. provided by the MUD library.
 */

#ifndef REQUEST_H
struct Request;
#endif
#ifndef EFFECTS_H
struct EffectsInfo;
#endif
#ifndef TYPES_H
struct Proc;
#endif

typedef struct {
    void *(*ms_AllocMem)(ULONG_T length);
    void (*ms_FreeMem)(void *p, ULONG_T len);
    BOOL_T (*ms_ReclaimMem)(BOOL_T panicing);
    BOOL_T (*ms_RecoverMem)(void);
    BOOL_T (*ms_RetryMem)(void);
    int (*ms_Open)(const char *fileName, int mode, ...);
    int (*ms_Close)(int fd);
    int (*ms_Read)(int fd, void *buffer, unsigned int len);

    void (*ms_abort)(BOOL_T isServerNuke);
    void (*ms_errorChar)(char ch);
    void (*ms_outputChar)(CHAR_T ch);

    /* server only */

    void (*ms_incRef)(ULONG_T key);
    void (*ms_decRef)(ULONG_T key);
    ULONG_T (*ms_lookup)(CHAR_T *name, UINT_T nameLen);
    CHAR_T *(*ms_findAnyName)(ULONG_T key);
    struct Proc *(*ms_findProc)(ULONG_T key, UINT_T **pLockCount);
    ULONG_T (*ms_writeProcNew)(BYTE_T *p, UINT_T len);
    struct Proc *(*ms_findBuiltin)(ULONG_T key);
    ULONG_T (*ms_getIntConstValue)(ULONG_T key);

    /* client only */

    void (*ms_putText)(CHAR_T *ptr, UINT_T len);
    void (*ms_setPrompt)(CHAR_T *newPrompt);
    void (*ms_setEcho)(BOOL_T echoOn);
    void (*ms_serverSend)(struct Request *rq);
    struct Request *(*ms_serverRequest)(struct Request *rq);
    void (*ms_handleAll)(BOOL_T wantInput);
    void (*ms_checkMessages)(void);
    void (*ms_getEffects)(struct EffectsInfo *ei);
    void (*ms_doEffects)(BYTE_T *buf, UINT_T len);
    BOOL_T (*ms_doEdit)(CHAR_T *buf, ULONG_T len, UINT_T mode, BOOL_T isProc,
			BOOL_T isLast, BOOL_T deleteFirst, CHAR_T *prompt);
    void (*ms_editErrorStart)(UINT_T line, UINT_T column);
    void (*ms_editErrorString)(CHAR_T *buf);
    void (*ms_editErrorEnd)(void);
    BOOL_T (*ms_getString)(CHAR_T *buf, CHAR_T *prompt, CHAR_T **pRes);
    void (*ms_defineEffect)(ULONG_T key, BYTE_T *data, UINT_T len);
    void (*ms_flushEffect)(ULONG_T key);

    /* private variables */

    BYTE_T ms_private[1000];
} MUDState_t;

extern struct Library *OpenMudLibrary(unsigned long int version);
extern void CloseMudLibrary(void);

extern struct Request *allocRequestE(MUDState_t *ms, ULONG_T len);
extern void freeRequestE(MUDState_t *ms, struct Request *rq);
extern void serverMessage(MUDState_t *ms, struct Request *rq);
extern void inputLine(MUDState_t *ms, CHAR_T *p, ULONG_T len);
extern void syncControl(MUDState_t *ms, ULONG_T onOff);
extern void rawKeyEvent(MUDState_t *ms, ULONG_T key);
extern void mouseUpEvent(MUDState_t *ms, ULONG_T number, ULONG_T position);
extern void buttonEvent(MUDState_t *ms, ULONG_T whichButton);
extern void releaseEffect(MUDState_t *ms, ULONG_T key);
extern void textResize(MUDState_t *ms, ULONG_T newRows, ULONG_T newCols);
extern ULONG_T parseActionFromString(MUDState_t *ms, BYTE_T *p, ULONG_T owner);
extern ULONG_T parseProcFromString(MUDState_t *ms, BYTE_T *p, ULONG_T owner);
extern void graphicsFlip(MUDState_t *ms, ULONG_T onOff);
extern void voiceFlip(MUDState_t *ms, ULONG_T onOff);
extern void soundFlip(MUDState_t *ms, ULONG_T onOff);
extern void musicFlip(MUDState_t *ms, ULONG_T onOff);
extern void effectDone(MUDState_t *ms, ULONG_T kind, ULONG_T id);
extern void editStringDone(MUDState_t *ms, CHAR_T *buf,ULONG_T len,ULONG_T ok);
extern void editProcStart(MUDState_t *ms);
extern void editProcDone(MUDState_t *ms);
extern void editProcCancel(MUDState_t *ms);
extern BOOL_T MUDInitialize(MUDState_t *ms, ULONG_T flags, ULONG_T rqLimit);
extern void MUDConnectMessage(MUDState_t *ms, struct Request *rq);
extern BOOL_T MUDConnected(MUDState_t *ms, struct Request *rq);
extern void MUDMain(MUDState_t *ms, CHAR_T *playerName, CHAR_T *password);
extern void MUDDisconnectMessage(MUDState_t *ms, struct Request *rq);
extern void MUDAbort(MUDState_t *ms);
extern void MUDShutDown(MUDState_t *ms);
extern void MUDTerminate(MUDState_t *ms);
extern BOOL_T MUDSource(MUDState_t *ms, CHAR_T *fileName);
extern void MUDCrypt(CHAR_T *p, ULONG_T decrypt, ULONG_T sessionKey);

/* flag bits for MUDInitialize */

#define FLAG_CACHE_PROCS	0x01
#define FLAG_CACHE_SYMBOLS	0x02
#define FLAG_IS_REMOTE		0x04
