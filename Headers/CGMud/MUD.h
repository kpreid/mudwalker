/*
 * Amiga MUD
 *
 * Copyright (c) 1997 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

#define MUD_BIG_ENDIAN		0
#define MUD_LITTLE_ENDIAN	1

/* You gotta pick one! Note that this defines the endianness of the host
   CPU. The database and all messages are in network byte order. */
#define MUD_ENDIAN		MUD_LITTLE_ENDIAN

/* If an unaliged fetch is cheaper than a series of byte-fetches, then
   do this, to speed up the byte-code machine. */

#define UNALIGNED_OK		1

/* Doing this makes porting from Draco much easier. There are also issues
   of the size of structures sent in messages, etc. Note: There are places
   in the code (e.g. bytecode stuff, procIO code, etc. that assumes that
   BYTE_T occupies 1 byte, UINT_T 2 bytes and ULONG_T 4 bytes. */

typedef unsigned char BYTE_T;
typedef unsigned char CHAR_T;	/* User character, not server internal */
typedef unsigned short int UINT_T;
typedef short int INT_T;
typedef unsigned long int ULONG_T;
typedef long int LONG_T;
typedef unsigned char BOOL_T;
/* Note: if these are made an enum, they cannot be used to control #if's */
#define B_FALSE 0
#define B_TRUE	1
#define P_NULL	0


#define LOG_NAME	"MUD.log"
#define INDEX_NAME	"MUD.index"
#define DATA_NAME	"MUD.data"

#define VERSION1	'1'
#define VERSION2	'1'
#define YEAR1		'9'
#define YEAR2		'9'
#define COPYRIGHT	0xa9

#define MUD_VERSION	((VERSION1 - '0') * 10 + (VERSION2 - '0'))
#define TEXT_LENGTH	4000
#define TEXT_COLUMNS	76
#define MAX_COLUMNS	256
#define PASSWORD_LEN	20
#define PLAYER_NAME_LEN 20

#define NAME_TRIES	3
#define YN_TRIES	3

#define ULONG_BITS	(sizeof(ULONG_T) * 8)
#define FRAC_BITS	16
#define MAX_FRAC	((1 << FRAC_BITS) - 1)

#define TAG_ALLOCS	B_TRUE

/*
 * smallest builtin function key
 */

#define SMALLEST_BUILTIN	0x00fff000

#define EDIT_COOKED	0
#define EDIT_RAW	1
#define EDIT_CODE	2

/*
 * Routines GRedrawIcons and GUndrawIcons are no longer present.
 */

#define REDRAW_ICONS	0
