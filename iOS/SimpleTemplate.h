//
//  SimpleTemplate.h
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


#import <Foundation/Foundation.h>

@interface SimpleTemplateRenderer : NSObject

- (SimpleTemplateRenderer*) initWithTemplate:(NSString*)template;
- (void) compile;
- (NSString*) renderFromMap:(NSDictionary*)map;

+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map;
+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map preserveWhitespace:(BOOL)preserveWhitespace;

@end
