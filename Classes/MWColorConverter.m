#import "MWColorConverter.h"

#import <Foundation/Foundation.h>
#import <MudWalker/MWConstants.h>

NSString *inames[] = {
  @"ansi-black",
  @"ansi-red",
  @"ansi-green", 
  @"ansi-yellow",
  @"ansi-blue",
  @"ansi-magenta",
  @"ansi-cyan",
  @"ansi-white",
  @"foreground",
  @"background",
};

NSString *snames[] = {
  @"foreground-local",
  @"foreground-echo",
  @"foreground-link",
};

id MWTestColorConverter(void) {
  NSMutableArray *a = [NSMutableArray array];
  int i;
  for (i = 0; i < MWCOLOR_MAXINDEX; i++) {
    [a addObject:[NSArray arrayWithObjects:
      [NSNumber numberWithInt:i],
      MWColorNameForIndex(i),
      [NSNumber numberWithInt:MWColorIndexForName(MWColorNameForIndex(i))],
      nil
    ]];
  }
  return a;
}

NSDictionary * MWColorDictionaryFromArray(NSArray *oldColorArray) {
  NSMutableDictionary *colorDictionary = [NSMutableDictionary dictionary];
  int i;
  for (i = 0; i < [oldColorArray count]; i++) {
    [colorDictionary setObject:[oldColorArray objectAtIndex:i] forKey:MWColorNameForIndex(i)];
  }
  return [[colorDictionary copy] autorelease];
}

NSString *MWColorNameForIndex(int index) {
  NSString *suffix;
  switch ((index / 10) * 10) {
    case MWCOLOR_GROUP_NORMAL:
      suffix = @"";
      break;
    case MWCOLOR_GROUP_BRIGHT:
      suffix = @"-bright";
      break;
    case MWCOLOR_GROUP_DIM:
      suffix = @"-dim";
      break;
    case MWCOLOR_GROUP_SPECIAL:
      if (index % 10 > 2)
        return @"junk";
      return snames[index % 10];
    default:
      return @"junk";
      break;
  }
  return [inames[index % 10] stringByAppendingString:suffix];
}
int MWColorIndexForName(NSString *name) {
  if ([name isEqual:@"foreground-local"])
    return MWCOLOR_SP_LOCAL;
  else if ([name isEqual:@"foreground-echo"])
    return MWCOLOR_SP_ECHO;
  else if ([name isEqual:@"foreground-link"])
    return MWCOLOR_SP_LINK;
  else {
    int group;
    if ([name hasSuffix:@"-bright"]) {
      name = [name substringToIndex:[name length] - [@"-bright" length]];
      group = MWCOLOR_GROUP_BRIGHT;
    } else if ([name hasSuffix:@"-dim"]) {
      name = [name substringToIndex:[name length] - [@"-dim" length]];
      group = MWCOLOR_GROUP_DIM;
    } else {
      group = MWCOLOR_GROUP_NORMAL;
    }
    int i;
    for (i = 0; i < sizeof(inames) / sizeof(*inames); i++) {
      if ([inames[i] isEqualToString:name])
        return group + i;
    }
    return group + MWCOLOR_INDEX_DFORE;
  }
}