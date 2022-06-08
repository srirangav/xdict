/*
    xdict.m - dictionary browser for MacOSX

    Inspired by: https://nshipster.com/dictionary-services/
                 https://github.com/mchinen/RSDeskDict/blob/master/RSDeskDict/AppDelegate.m
                 https://stackoverflow.com/questions/22580539/
                 https://9fans.github.io/plan9port/man/man1/dict.html

    History:

    v. 0.1.0 (06/06/2022) - Initial version
    v. 0.1.1 (06/07/2022) - remove unneeded prototypes
    v. 0.2.0 (06/08/2022) - add support for commands and format definitions

    Copyright (c) 2022 Sriranga R. Veeraraghavan <ranga@calalum.org>

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <AppKit/AppKit.h>
#import <CoreServices/CoreServices.h>
#import <stdio.h>
#import <unistd.h>
#import <strings.h>

/*
    Dictionary Services API
    See: https://nshipster.com/dictionary-services/
*/

extern CFArrayRef  DCSCopyAvailableDictionaries(void);
extern CFStringRef DCSDictionaryGetName(DCSDictionaryRef dict);
extern CFStringRef DCSDictionaryGetShortName(DCSDictionaryRef dict);
extern CFArrayRef  DCSCopyRecordsForSearchString(DCSDictionaryRef dict,
                                                 CFStringRef string,
                                                 void *,
                                                 void *);
extern CFStringRef DCSRecordCopyData(CFTypeRef record);
extern CFStringRef DCSRecordGetHeadword(CFTypeRef record);
extern CFStringRef DCSRecordGetRawHeadword(CFTypeRef record);

/* xdict options */

typedef struct
{
    bool headwordOnly;
    bool html;
    bool raw;
} xdictOpts_t;

/* globals */

enum
{
    gPgmOptCmd      = 'c',
    gPgmOptDict     = 'd',
    gPgmOptHelp     = 'h',
    gPgmOptList     = 'l',
};

static const char *gPgmOpts = "c:d:hl";
static const char *gPgmName = "xdict";
static const char *gPgmOptListDicts = "?";

/* commands */

static const char *gPgmCmdHeadwordLong = "headword";
static const char *gPgmCmdHeadwordShort = "h";
static const char *gPgmCmdHtmlLong = "html";
static const char *gPgmCmdHtmlShort = "m";
static const char *gPgmCmdRawLong = "raw";
static const char *gPgmCmdRawShort = "r";

/* prototypes */

static void printUsage(void);
static bool isArg(const char *arg,
                  const char *longMode,
                  const char *shortMode);
static int  listDictionaries(void);
static int  printDefinition(const char *word,
                            NSString *dict,
                            xdictOpts_t *opts);
static void printFormattedDefinition(NSString *definition);

/* printUsage - print the usage message */

static void printUsage(void)
{
    fprintf(stderr,
            "Usage: %s [-%c] | [-%c [dictionary] [-%c [command]] [word]\n",
            gPgmName,
            gPgmOptList,
            gPgmOptDict,
            gPgmOptCmd);
}

/* isArg - check if the arg is the requested mode */

static bool isArg(const char *arg,
           const char *longMode,
           const char *shortMode)
{
    size_t modeStrLen = 0;

    if (arg == NULL || arg[0] == '\0')
    {
        return false;
    }

    if (longMode != NULL)
    {
        modeStrLen = strlen(longMode);
        if (modeStrLen > 1 &&
            strncasecmp(arg, longMode, modeStrLen) == 0)
        {
            if (strlen(arg) == modeStrLen)
            {
                return true;
            }
            return false;
        }
    }

    if (shortMode == NULL)
    {
        return false;
    }

    modeStrLen = strlen(shortMode);
    if (modeStrLen < 1)
    {
        return false;
    }

    if (strncasecmp(arg, shortMode, modeStrLen) == 0 &&
        strlen(arg) == modeStrLen)
    {
        return true;
    }

    return false;
}


/* 
    listDictionaries - list all available dictionaries

    TODO: Use short names for sorting before long names
*/

static int listDictionaries(void)
{
    NSString *name = nil;
    NSArray *dictList = nil, *sortedDictNames = nil, *dictNames = nil;
    NSMutableDictionary *dicts = nil;
    id dict, dictName;
    int i = 1;

    /* get all available dictionaries */

    dictList =
        (__bridge_transfer NSArray *)DCSCopyAvailableDictionaries();
    if (dictList == nil || [dictList count] <= 0)
    {
        return 1;
    }

    dicts = [NSMutableDictionary dictionaryWithCapacity: [dictList count]];
    if (dicts == nil)
    {
        return 1;
    }

    /* extract the names of the dictionaries */

    for (dict in dictList)
    {
        name = (__bridge NSString *)DCSDictionaryGetName(
            (__bridge DCSDictionaryRef)dict);
        if (name != nil)
        {
            [dicts setObject: dict
                      forKey: name];
        }
    }

    if ([dicts count] <= 0)
    {
        return 1;
    }

    dictNames = [dicts allKeys];
    if (dictNames == nil || [dictNames count] <= 0)
    {
        return 1;
    }

    /* sort the dictionary names */

    sortedDictNames = [dictNames sortedArrayUsingSelector:
        @selector(localizedCaseInsensitiveCompare:)];
    if (sortedDictNames == nil)
    {
        return 1;
    }

    /* print out the dictionary names */

    for (dictName in sortedDictNames)
    {
        if (dictName == nil)
        {
            continue;
        }

        fprintf(stdout, "[%2d] ", i);

        dict = [dicts objectForKey: dictName];
        if (dict == nil)
        {
            continue;
        }

        name = (__bridge NSString *)DCSDictionaryGetShortName(
            (__bridge DCSDictionaryRef)dict);
        if (name != nil &&
            [name caseInsensitiveCompare: dictName] != NSOrderedSame)
        {
            fprintf(stdout,
                    "%s (%s)",
                    [name cStringUsingEncoding: NSUTF8StringEncoding],
                    [dictName cStringUsingEncoding: NSUTF8StringEncoding]);
        }
        else
        {
            fprintf(stdout,
                    "%s",
                    [dictName cStringUsingEncoding: NSUTF8StringEncoding]);
        }

        fprintf(stdout, "\n");
        i++;
    }

    return 0;
}

/* printFormattedDefinition - format and print a definition */

static void printFormattedDefinition(NSString *definition)
{
    NSMutableString *formattedDef = nil;

    if (definition == nil)
    {
        return;
    }

    formattedDef = 
        [[definition stringByReplacingOccurrencesOfString: @" 1 "
                                               withString: @"\n  1 "]
        mutableCopy];

    if (formattedDef == nil)
    {
        fprintf(stdout,
                "%s\n",
                [definition cStringUsingEncoding: NSUTF8StringEncoding]);
        return;
    }


    if (@available(macos 10.7, *))
    {
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression 
            regularExpressionWithPattern: @"([▸•●] )"
                                 options: 0
                                   error: &error];
        if (regex != nil)
        {
            [regex replaceMatchesInString: formattedDef
                                  options: NSMatchingWithTransparentBounds
                                    range: NSMakeRange(0, 
                                           [formattedDef length])
                             withTemplate: @"\n    $1"];
        }

        regex = [NSRegularExpression 
            regularExpressionWithPattern: 
    //                                    @"([\\)\\.]+)\\s+(\\d+)\\s"
                @"\\s+(\\d+\\s[\\[\\[\\(])"
                                 options: 0
                                   error: &error];
        if (regex != nil)
        {
            [regex replaceMatchesInString: formattedDef
                                  options: 
                                  NSMatchingWithTransparentBounds
                                    range: NSMakeRange(0, 
                                           [formattedDef length])
                             withTemplate: @"\n  $1"];
        }

        regex = [NSRegularExpression 
            regularExpressionWithPattern: @"(\\D)\\.\\s(\\S)"
                                 options: NSRegularExpressionCaseInsensitive
                    error: &error];
        if (regex != nil)
        {
            [regex replaceMatchesInString: formattedDef
                                  options: 
                                  NSMatchingWithTransparentBounds
                                    range: NSMakeRange(0, 
                                           [formattedDef length])
                             withTemplate: @"$1.\n  $2"];
        }

        regex = [NSRegularExpression 
            regularExpressionWithPattern: @"Word Links sections.*\\."
                                 options: 0
                    error: &error];
        if (regex != nil)
        {
            [regex replaceMatchesInString: formattedDef
                                  options: 
                                  NSMatchingWithTransparentBounds
                                    range: NSMakeRange(0, 
                                           [formattedDef length])
                             withTemplate: @"\n"];
        }
    }

    [formattedDef replaceOccurrencesOfString: @".verb"
                                  withString: @".\nverb "
                                     options: NSLiteralSearch
                                       range: NSMakeRange(0, 
                                       [formattedDef length])];

    [formattedDef replaceOccurrencesOfString: @"PHRASES"
                                  withString: @"\nPHRASES\n "
                                     options: NSLiteralSearch
                                       range: NSMakeRange(0, 
                                       [formattedDef length])];

    [formattedDef replaceOccurrencesOfString: @"PHRASAL VERBS"
                                  withString: @"\nPHRASAL VERBS\n "
                                     options: NSLiteralSearch
                                       range: NSMakeRange(0, 
                                       [formattedDef length])];

    [formattedDef replaceOccurrencesOfString: @"DERIVATIVES"
                                  withString: @"\nDERIVATIVES\n "
                                     options: NSLiteralSearch
                                       range: NSMakeRange(0, 
                                       [formattedDef length])];

    [formattedDef replaceOccurrencesOfString: @"ORIGIN"
                                  withString: @"\nORIGIN\n "
                                     options: NSLiteralSearch
                                       range: NSMakeRange(0, 
                                       [formattedDef length])];

    [formattedDef replaceOccurrencesOfString: @"IDIOME"
                                  withString: @"\nIDIOME\n "
                                     options: NSLiteralSearch
                                       range: NSMakeRange(0, 
                                       [formattedDef length])];

    [formattedDef replaceOccurrencesOfString: @"WORD LINKS"
                                  withString: @"\nWORD LINKS\n "
                                     options: NSLiteralSearch
                                       range: NSMakeRange(0, 
                                       [formattedDef length])];

    [formattedDef replaceOccurrencesOfString: @" | )"
                                  withString: @")"
                                     options: NSLiteralSearch
                                       range: NSMakeRange(0, 
                                       [formattedDef length])];

    fprintf(stdout,
            "%s\n",
            [formattedDef cStringUsingEncoding: NSUTF8StringEncoding]);
}

/*
    printDefinition - print the definition for the given word
                      using the specified dictionary
 */

static int printDefinition(const char *rawWord,
                           NSString *dictName,
                           xdictOpts_t *opts)
{
    NSString *wordStr = nil, *trimmedWord = nil;
    NSString *title =  nil, *definition = nil, *prev = nil;
    NSString *trimmedDict = nil, *name = nil;
    NSArray *records = nil;
    NSUInteger numRecs = 0;
    DCSDictionaryRef dictRef = nil;
    id dict, record;
    int ret = 1, i = 1;
    bool printHtml = false;
    bool printHeadword = false;
    bool printRaw = false;

    if (rawWord == NULL || rawWord[0] == '\0')
    {
        fprintf(stderr,"ERROR: no word provided\n");
        return ret;
    }

    if (opts != NULL)
    {
        if (opts->headwordOnly == true)
        {
            printHeadword = true;
        }
        else if (opts->html == true)
        {
            printHtml = true;
        }
        else if (opts->raw == true)
        {
            printRaw = true;
        }
    }

    wordStr = [[NSString alloc] initWithCString: rawWord
                                       encoding: NSUTF8StringEncoding];
    if (wordStr == nil)
    {
        fprintf(stderr,"ERROR: cannot convert '%s'\n", rawWord);
        return ret;
    }

    trimmedWord = [wordStr stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedWord == nil)
    {
        fprintf(stderr,"ERROR: cannot trim '%s'\n", rawWord);
        return ret;
    }

    /*
        if no dictionary is specified, search the default dictionary
        for a definition
    */

    if (dictName == nil)
    {
        definition = (__bridge_transfer NSString *)DCSCopyTextDefinition(
            NULL,
            (__bridge CFStringRef)trimmedWord,
            CFRangeMake(0, (CFIndex)[trimmedWord length]));
        printFormattedDefinition(definition);
        return 0;
    }

    /* search in the specified dictionary */

    trimmedDict = [dictName stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedDict == nil)
    {
        fprintf(stderr,
                "ERROR: cannot trim dictionary '%s'\n",
                [dictName cStringUsingEncoding: NSUTF8StringEncoding]);
        return ret;
    }

    /* try to find the requested dictionary */

    for (dict in
         (__bridge_transfer NSArray *)DCSCopyAvailableDictionaries())
    {
        name = (__bridge NSString *)DCSDictionaryGetName(
                (__bridge DCSDictionaryRef)dict);
        if (name == nil)
        {
            continue;
        }

        if ([name caseInsensitiveCompare: dictName] == NSOrderedSame)
        {
            dictRef = (__bridge DCSDictionaryRef)dict;
            break;
        }

        /* try the short name */

        name = (__bridge NSString *)DCSDictionaryGetShortName(
                (__bridge DCSDictionaryRef)dict);
        if (name == nil)
        {
            continue;
        }

        if ([name caseInsensitiveCompare: dictName] == NSOrderedSame)
        {
            dictRef = (__bridge DCSDictionaryRef)dict;
            break;
        }
    }

    /* didn't find the requested dictionary, return */

    if (dictRef == nil)
    {
        fprintf(stderr,
                "ERROR: could not find dictionary '%s'\n",
                [dictName cStringUsingEncoding: NSUTF8StringEncoding]);
        return ret;
    }

    /*
        look for definitions for the requested word in the
        requested dictionary
    */

    records = (__bridge_transfer NSArray *)DCSCopyRecordsForSearchString(
            (__bridge DCSDictionaryRef)dict,
            (__bridge CFStringRef)trimmedWord,
            NULL,
            NULL);
    if (records == nil)
    {
        fprintf(stderr,
                "ERROR:  no definitions found for '%s'\n",
                rawWord);
        return ret;
    }

    numRecs = [records count];
    if (numRecs <= 0)
    {
        fprintf(stderr,
                "ERROR:  no definitions found for '%s'\n",
                rawWord);
        return ret;
    }

    ret = 0;

    for (record in records)
    {
        title = (__bridge NSString *)DCSRecordGetRawHeadword(
                    (__bridge CFTypeRef)record);
        if (title == nil)
        {
            ret++;
            continue;
        }

        if (printHeadword)
        {
            fprintf(stdout,
                    "%s\n",
                    [title cStringUsingEncoding: NSUTF8StringEncoding]);
            break;
        }

        if (printHtml)
        {
            definition = (__bridge_transfer NSString*)DCSRecordCopyData(
                    (__bridge CFTypeRef)record);
        }
        else
        {
            definition = (__bridge_transfer NSString*)DCSCopyTextDefinition(
                    (__bridge DCSDictionaryRef)dict,
                    (__bridge CFStringRef)title,
                    CFRangeMake(0, (CFIndex)[title length]));
        }

        if (definition == nil)
        {
            ret++;
            continue;
        }

        if (prev == nil || ![prev isEqualToString: definition])
        {
            if (printHtml == false && printRaw == false && numRecs > 1)
            {
                fprintf(stdout, "[%2d] ", i);
            }

            if (printRaw == true)
            {
                fprintf(stdout,
                        "%s\n",
                        [definition cStringUsingEncoding:
                            NSUTF8StringEncoding]);
            }
            else
            {
                printFormattedDefinition(definition);
            }
            i++;
        }

        prev = definition;
    }

    return ret;
}

/* main */

int main(int argc, char * const argv[])
{
    int err = 0, ch = 0;
    BOOL optList = NO, optHelp = NO;
    NSString *dict = nil;
    xdictOpts_t opts;

@autoreleasepool
    {

    if (argc <= 1)
    {
        printUsage();
        return 1;
    }

    opts.headwordOnly = false;
    opts.html = false;
    opts.raw = false;

    while ((ch = getopt(argc, argv, gPgmOpts)) != -1)
    {
        switch(ch)
        {
            case gPgmOptHelp:
                optHelp = YES;
                break;
            case gPgmOptList:
                optList = YES;
                break;
            case gPgmOptCmd:

                if (optarg[0] == '\0')
                {
                    fprintf(stderr,"Error: No command specified\n");
                    err++;
                }
                else if (isArg(optarg,
                               gPgmCmdHeadwordLong,
                               gPgmCmdHeadwordShort) == true)
                {
                    opts.headwordOnly = true;
                }
                else if (isArg(optarg,
                               gPgmCmdHtmlLong,
                               gPgmCmdHtmlShort) == true)
                {
                    opts.html = true;
                    opts.raw = false;
                }
                else if (isArg(optarg,
                               gPgmCmdRawLong,
                               gPgmCmdRawShort) == true)
                {
                    opts.raw = true;
                    opts.html = false;
                }
                else
                {
                    fprintf(stderr,
                            "Error: Unknown command: '%s'\n",
                            optarg);
                    err++;
                }
                break;

            case gPgmOptDict:

                if (optarg[0] == '\0')
                {
                    fprintf(stderr,"Error: No dictionary specified\n");
                    err++;
                }
                else if (strcmp(optarg, gPgmOptListDicts) == 0)
                {
                    optList = YES;
                }
                else
                {
                    dict = [[NSString alloc]
                        initWithCString: optarg
                               encoding: NSUTF8StringEncoding];
                }

                break;

            default:
                fprintf(stderr, "Unknown option: '%c'\n", ch);
                err++;
                break;
        }

        if (optHelp || err > 0)
        {
            printUsage();
            break;
        }

        if (optList)
        {
            break;
        }
    }

    if (err > 0)
    {
        return err;
    }

    if (optHelp)
    {
        return 0;
    }

    if (optList)
    {
        if (dict == nil)
        {
            return listDictionaries();
        }

        fprintf(stderr,
                "ERROR: Cannot combine -%c and -%c\n",
                gPgmOptList,
                gPgmOptDict);
        printUsage();
        return 1;
    }

    argc -= optind;
    argv += optind;

    if (argc <= 0)
    {
        fprintf(stderr, "Error: No word specified\n");
        printUsage();
        return 1;
    }

    return printDefinition(argv[0], dict, &opts);

    } /* @autoreleasepool */
}
