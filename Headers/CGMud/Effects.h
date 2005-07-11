/*
 * Amiga MUD
 *
 * Copyright (c) 1997 by Chris Gray
 *
 * CGMud Copyright (c) 2001 by Chris Gray
 */

/*
 * Effects.h - codes for the various effects.
 */

#define EFFECTS_H

enum {
    ef_null,
    ef_Else,
    ef_Fi,
    ef_IfFound,
    ef_FailText,
    ef_Abort,
    ef_Call,
    ef_PlaceCursor,
    ef_PlaceCursorShort,
    ef_RemoveCursor,
    ef_SetCursorPen,
    ef_SetCursorPattern,
    ef_AddButton,
    ef_EraseButton,
    ef_ClearButtons,
    ef_AddRegion,
    ef_EraseRegion,
    ef_ClearRegions,
    ef_SetButtonPen,
    ef_SetPen,
    ef_SetColour,
    ef_ResetColours,
    ef_Clear,
    ef_Pixel,
    ef_PixelRow,
    ef_AMove,
    ef_AMoveShort,
    ef_RMove,
    ef_RMoveShort,
    ef_ADraw,
    ef_ADrawShort,
    ef_RDraw,
    ef_RDrawShort,
    ef_Rectangle,
    ef_Circle,
    ef_Ellipse,
    ef_PolygonStart,
    ef_PolygonEnd,
    ef_DefineTile,
    ef_DefineOverlayTile,
    ef_DisplayTile,
    ef_SetTextColour,
    ef_Text,
    ef_LoadBackGround,
    ef_SetImage,
    ef_ShowImage,
    ef_ShowImagePixels,
    ef_ShowBrush,
    ef_ScrollRectangle,
    ef_SetIconPen,
    ef_NewIcon,
    ef_ShowIcon,
    ef_RemoveIcon,
    ef_DeleteIcon,
    ef_ResetIcons,
#if REDRAW_ICONS
    ef_RedrawIcons,
    ef_UndrawIcons,
#endif
    ef_SoundVolume,
    ef_PlaySound,
    ef_Params,
    ef_VReset,
    ef_VoiceVolume,
    ef_Narrate,
    ef_MusicVolume,
    ef_PlaySong,

    ef_last
};
typedef unsigned char EffectType_t;

#define BEGIN_KEY_LEN				24

typedef struct EffectsInfo {
    char ei_key[BEGIN_KEY_LEN];			/* Must be first field */
    char ei_graphicsType[20];
    UINT_T ei_graphicsRows, ei_graphicsCols;
    UINT_T ei_graphicsColours;
    UINT_T ei_fontAscent;
    UINT_T ei_fontDescent;
    UINT_T ei_fontLeading;
    UINT_T ei_fontHeight;
    UINT_T ei_fontWidth;
    UINT_T ei_textWidth, ei_textHeight;
    UINT_T ei_version;
    BOOL_T ei_canEdit, ei_canGetString, ei_canQueryFile, ei_canWizard;
    BOOL_T ei_graphicsOn, ei_graphicsPalette;
    BOOL_T ei_voiceOn, ei_soundOn, ei_musicOn;
} EffectsInfo_t;
