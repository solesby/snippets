//
//  SimpleTemplate.m
//
//  Created by Adam Solesby
//  http://github.com/solesby
//  Copyright (c) 2013 Adam Solesby. All rights reserved.
//

/*
 *  This is a very very simple text "template" parser. It will parse a string to identify
 *  blocks. Then it will conditionally evaluate those blocks and replace variables with
 *  content provided by a data dictionary.
 *
 *  A block is designated like this:
 *
 *      {% condition %}
 *         ... block content ...
 *      {% end %}
 *
 *  The parser evaluates the presense (and length if its a string) of an object in the data
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
 */


#import "SimpleTemplate.h"

@interface SimpleTemplateRenderer ()

@property (nonatomic,strong) NSString* template;

@property (nonatomic,strong) NSMutableArray* blocks;
@property (nonatomic,strong) NSMutableArray* conditions;

@end

@implementation SimpleTemplateRenderer

- (SimpleTemplateRenderer*) initWithTemplate:(NSString*)template
{
    self = [super init];
    if (self)
    {
        _template = template;
        _blocks = [[NSMutableArray alloc] init];
        _conditions = [[NSMutableArray alloc] init];
    }
    return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) compile
{
    if (!_template) return;

    NSScanner* scanner = [[NSScanner alloc] initWithString:_template];
    [scanner setCharactersToBeSkipped:nil]; // default is to skip whitespace which would require content between blocks

    NSString* block = nil;
    NSString* cond = nil;
    
    [_conditions addObject:@""]; // first block can't have a condition
    
    while([scanner scanUpToString:@"{%" intoString:&block])
    {
        [_blocks addObject:[NSString stringWithString:block]];
        
        if([scanner isAtEnd]) break; // finished processing

        cond = nil;
        
        [scanner scanString:@"{%"     intoString:nil];
        [scanner scanUpToString:@"%}" intoString:&cond];
        [scanner scanString:@"%}"     intoString:nil];
        
        cond = [cond stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([cond isEqualToString:@"end"]) cond = nil;
        
        [_conditions addObject: cond ? [NSString stringWithString:cond] : @"" ];
    }

    //NSLog(@"Found %d(%d) blocks: %@", _blocks.count, _conditions.count, _conditions);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString*) renderFromMap:(NSDictionary*)map
{
    NSMutableString* buffer = [NSMutableString new];

    for( NSUInteger i = 0; i < _blocks.count; i++ )
    {
        NSString* block = _blocks[i];
        NSString* cond = _conditions[i];
        //NSLog(@"cond:%@ block:%@", cond, block);
        
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
            else if ([obj isKindOfClass:[NSArray class]])
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

        
    }
    
    return [NSString stringWithString:buffer];
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map
{
    return [SimpleTemplateRenderer stringWithTemplate:template fromMap:map preserveWhitespace:YES];
}

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
+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map preserveWhitespace:(BOOL)preserveWhitespace
{
    NSMutableString* buffer = [NSMutableString new];
    NSScanner* scanner = [[NSScanner alloc] initWithString:template];
    if (preserveWhitespace) [scanner setCharactersToBeSkipped:nil];
    
    NSString* chunkToOutput = nil;
    
    while([scanner scanUpToString:@"{{" intoString:&chunkToOutput])
    {
        NSString* key = nil;
        NSString* value = nil;
        
        [buffer appendString:chunkToOutput];
        
        if([scanner isAtEnd]) break; // finished processing
        
        [scanner scanString:@"{{"     intoString:nil];
        [scanner scanUpToString:@"}}" intoString:&key];
        [scanner scanString:@"}}"     intoString:nil];
        
        if(key)
        {
            key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            value = [map objectForKey:key];
        }
        
        // if(value) [buffer appendString:[self htmlFromAttributedString:value]];
        if(value) [buffer appendString:value];
        else      [buffer appendFormat:@"{{%@}}", key];
    }
    
    return [NSString stringWithString:buffer];
}

@end
