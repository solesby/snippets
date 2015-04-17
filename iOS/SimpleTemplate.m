//
//  SimpleTemplate.m
//
//  Created by Adam Solesby
//  http://github.com/solesby
//  Copyright (c) 2013 Adam Solesby. All rights reserved.
//
//  The MIT License (MIT)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/*
 *  This is a very very simple text "template" parser. It will parse a string to identify
 *  blocks. Then it will conditionally evaluate those blocks and replace variables with
 *  content provided by a data dictionary.
 *
 *  A block is designated like this:
 *
 *      {% condition %}
 *         ... block content ...
 *      {% another_condition %}
 *         ... block content ...
 *      {% end %}
 *
 *  The parser evaluates the {% %} and breaks the template into chunks. {% end %} is optional.
 *
 *  The renderer evaluates the presense (and length if its a string) of an object in the data
 *  dictionary with key "condition". If the object exists and has length, then the block is
 *  evaluated. If the object in the dictionary is an array, then the block is evaluated for
 *  every item (dictionary) in the array.
 *
 *  Blocks CANNOT be nested.
 *
 *  Whenever the templates sees a variable like:
 *
 *      {{ variable }}
 *
 *  it looks for the presence of the variable in the data dictionary (or array item
 *  dictionary) and appends the object as a string.
 *
 *  Multiple variables can be used (for defaults). The first one found will be output:
 *
 *      {{ variable1 | variable2 | variable3 | "static text" }}
 *
 *  The rendered result of a block can be passed through a "filter" such as:
 *
 *      {% condition truncate:15 %}
 *      {% condition strip %}
 *      {% condition upper %}
 *      {% condition lower %}
 *
 *  If you load from `templatePath` instead of a string, you can "extend" other templates by
 *  using the following at the very beginning:
 *
 *      {% require another_template.txt %}
 *
 *  That will insert the contents of the template specified by `templatePath` into the contents
 *  of `another_template.txt` by replacing the string:
 *
 *      {% insert_required %}
 *
 */


#import "SimpleTemplate.h"

@interface SimpleTemplateRenderer ()

@property (nonatomic,strong) NSString* renderedOutput;
@property (nonatomic,strong) NSString* template;
@property (nonatomic,strong) NSString* templatePath;
@property (nonatomic) BOOL compiled;

@property (nonatomic,strong) NSMutableArray* blocks;
@property (nonatomic,strong) NSMutableArray* conditions;
@property (nonatomic,strong) NSMutableArray* filters;


@end

@implementation SimpleTemplateRenderer

- (SimpleTemplateRenderer*) initWithTemplatePath:(NSString*)templatePath
{
    NSError*  error;
    NSString* template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:&error];
    _templatePath = templatePath;

    // only combine files when using paths
    if ([template hasPrefix:@"{% require "])
    {
        NSString* trimmedTemplate = nil;
        NSString* requiredFilename = nil;
        NSScanner* scanner = [[NSScanner alloc] initWithString:template];
        [scanner scanString:@"{% require " intoString:nil];
        [scanner scanUpToString:@"%}" intoString:&requiredFilename];
        [scanner scanString:@"%}" intoString:nil];
        [scanner scanUpToString:@"ENDOFDOCUMENT" intoString:&trimmedTemplate]; // HACK: how do you scan to end of string?
        requiredFilename = [requiredFilename stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSString* requiredPath = [[templatePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:requiredFilename];
        NSString* wrapper = [NSString stringWithContentsOfFile:requiredPath encoding:NSUTF8StringEncoding error:&error];
        template = [wrapper stringByReplacingOccurrencesOfString:@"{% insert_required %}" withString:trimmedTemplate ? trimmedTemplate : @""];
    }
    
    return [self initWithTemplate:template];
}

- (SimpleTemplateRenderer*) initWithTemplate:(NSString*)template
{
    self = [super init];
    if (self)
    {
        _template = template;
        _blocks = [[NSMutableArray alloc] init];
        _conditions = [[NSMutableArray alloc] init];
        _filters = [[NSMutableArray alloc] init];
    }
    return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) compile
{
    if (!_template) return;

    // first remove comments
    NSString* template = [_template stringByReplacingOccurrencesOfString:@"\\{#.*?#\\}" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, _template.length)];
    
    // process special tags
    template = [template stringByReplacingOccurrencesOfString:@"\\{% *now *%\\}"
                   withString:[[NSDate date] description] options:NSRegularExpressionSearch range:NSMakeRange(0, template.length)];
    
    NSScanner* scanner = [[NSScanner alloc] initWithString:template];
    [scanner setCharactersToBeSkipped:nil]; // default is to skip whitespace which would require content between blocks

    NSString* block = nil;
    NSString* cond = nil;
    NSString* filter = nil;
    
    while(![scanner isAtEnd])
    {
        // scan block contents if cond was previously captured set it
        [scanner scanUpToString:@"{%" intoString:&block];
        
        if (block && block.length)
        {
            [_blocks     addObject: block  ? [NSString stringWithString:block]  : @""];
            [_conditions addObject: cond   ? [NSString stringWithString:cond]   : @""];
            [_filters    addObject: filter ? [NSString stringWithString:filter] : @""];
        }
        
        // reset
        block  = nil;
        cond   = nil;
        filter = nil;

        // check for condition on next block
        [scanner scanString:@"{%"     intoString:nil];
        [scanner scanUpToString:@"%}" intoString:&cond];
        [scanner scanString:@"%}"     intoString:nil];
        
        cond = [cond stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([cond isEqualToString:@"end"]) cond = nil;
        else
        {
            NSArray* parts = [cond componentsSeparatedByString:@" "];
            if (parts.count==2)
            {
                cond = parts[0];
                filter = parts[1];
            }
        }
    }
    
    _compiled = YES;

    //NSLog(@"Found %d(%d) blocks: %@", _blocks.count, _conditions.count, _conditions);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString*) renderFromMap:(NSDictionary*)map
{
    return [self renderFromMap:map trimWhitespace:NO];
}

- (NSString*) renderFromMap:(NSDictionary*)map trimWhitespace:(BOOL)trimWhitespace
{
    if (!_compiled) [self compile];
    
    NSMutableString* output = [NSMutableString new];

    for( NSUInteger i = 0; i < _blocks.count; i++ )
    {
        NSString* block = _blocks[i];
        NSString* cond = _conditions[i];
        NSString* filter = _filters[i];
        //NSLog(@"cond:%@ block:%@", cond, block);
        
        NSMutableString* buffer = [NSMutableString new];
        
        if (cond && cond.length)
        {
            NSObject* obj = [map objectForKey:cond];
            
            // if obj is array, render for every dictionary in the array
            if ([obj isKindOfClass:[NSArray class]])
            {
                for (NSDictionary* itemMap in (NSArray*) obj)
                {
                    [buffer appendString: [SimpleTemplateRenderer stringWithTemplate:block fromMap:itemMap] ];
                }
            }

            // if key matches a string, then the string must have a length
            else if ([obj isKindOfClass:[NSString class]])
            {
                if ([(NSString*) obj length])
                    [buffer appendString: [SimpleTemplateRenderer stringWithTemplate:block fromMap:map] ];
            }
                
            // if key matches an object in dictionary
            else if (obj)
                [buffer appendString: [SimpleTemplateRenderer stringWithTemplate:block fromMap:map] ];
            
            // otherwise skip block
        }
        else
            [buffer appendString: [SimpleTemplateRenderer stringWithTemplate:block fromMap:map] ];

        // now process block filters
        if ([filter hasPrefix:@"truncate:"])
        {
            NSInteger length = [[[filter componentsSeparatedByString:@":"] objectAtIndex:1] integerValue];
            if (length && buffer.length > length)
            {
                buffer = [NSMutableString stringWithFormat:@"%@…", [buffer substringToIndex:length-1]];
            }
        }
        else if ([filter isEqualToString:@"upper"]) { buffer = [[buffer uppercaseString] mutableCopy]; }
        else if ([filter isEqualToString:@"lower"]) { buffer = [[buffer lowercaseString] mutableCopy]; }
        else if ([filter isEqualToString:@"strip"]) {
            buffer = [[buffer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy]; }

        // finally append block result to template output
        [output appendString:buffer];
    }

    if (trimWhitespace)
        _renderedOutput = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    else
        _renderedOutput = [NSString stringWithString:output];


#if SIMPLETEMLPATE_SAVE_OUTPUT
    
    NSString *debugFilename = _templatePath ? [_templatePath lastPathComponent] : @"debug.txt";
    NSString *debugFilepath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"STDEBUG_%@", debugFilename] ];
    NSLog(@"## SimpleTemplate Debug: %@", debugFilepath);
    [_renderedOutput writeToFile:debugFilepath  atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
#endif

    return _renderedOutput;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) htmlFromAttributedString:(NSString*)string
{
    if ([string isKindOfClass:[NSAttributedString class]])
    {
        // TODO: ideally AttributedStrings should be rendered with style
        //
        // NSArray * exclude = [NSArray arrayWithObjects:@"doctype",@"html",@"head",@"body",@"xml",nil ];
        // NSDictionary *documentAttributes = [NSDictionary dictionaryWithObjectsAndKeys:NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute,
        //                                     exclude, NSExcludedElementsDocumentAttribute,
        //                                     nil];
        // NSData *htmlData = [(NSAttributedString*)string dataFromRange:NSMakeRange(0, string.length) documentAttributes:documentAttributes error:NULL];
        // return [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];

        return [(NSAttributedString*)string string];
    }
    return string;
}

+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map
{
    return [SimpleTemplateRenderer stringWithTemplate:template fromMap:map preserveWhitespace:YES];
}
+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map preserveWhitespace:(BOOL)preserveWhitespace
{
    return [SimpleTemplateRenderer stringWithTemplate:template fromMap:map preserveWhitespace:YES start:nil end:nil];
}
+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map preserveWhitespace:(BOOL)preserveWhitespace start:(NSString*)start end:(NSString*)end
{
    if (start==nil) { start = @"{{"; end = @"}}"; }
    NSMutableString* buffer = [NSMutableString new];
    NSScanner* scanner = [[NSScanner alloc] initWithString:template];
    if (preserveWhitespace) [scanner setCharactersToBeSkipped:nil];
    
    NSString* chunkToOutput = nil;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM dd, yyyy HH:mm"];
    NSString *dateFormat = [map objectForKey:@"_dateFormat"];
    if (dateFormat) [dateFormatter setDateFormat:dateFormat];
    
    while(![scanner isAtEnd])
    {
        NSString* keyString = nil;
        id value = nil;
        
        [scanner scanUpToString:start intoString:&chunkToOutput];
        if (chunkToOutput) [buffer appendString:chunkToOutput];
        chunkToOutput = nil;
        
        if([scanner isAtEnd]) break; // finished processing
        
        [scanner scanString:start   intoString:nil];
        [scanner scanUpToString:end intoString:&keyString];
        [scanner scanString:end     intoString:nil];
        
        if(keyString)
        {
            NSString* key;
            for (key in [keyString componentsSeparatedByString:@"|"])
            {
                key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (!key.length) continue;
                
                if ([key hasPrefix:@"\""])
                {
                    [buffer appendString:[key stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]]];
                    break;
                }

                value = [map objectForKey:key];

                if ([value isKindOfClass:[NSDate class]])
                    value = [dateFormatter stringFromDate:(NSDate*)value];

                if([value isKindOfClass:[NSString class]] && [value length])
                {
                    // TODO: [buffer appendString:[self htmlFromAttributedString:value]];
                    [buffer appendString:value];

                    break; // once we've output something stop checking variables
                }
            }
        }
    }
    
    return [NSString stringWithString:buffer];
}


@end
