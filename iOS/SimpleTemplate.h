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

#define SIMPLETEMLPATE_SAVE_OUTPUT 0

#import <Foundation/Foundation.h>

@interface SimpleTemplateRenderer : NSObject

- (SimpleTemplateRenderer*) initWithTemplate:(NSString*)template;
- (SimpleTemplateRenderer*) initWithTemplatePath:(NSString*)templatePath;

- (void) compile;
- (NSString*) renderFromMap:(NSDictionary*)map;
- (NSString*) renderFromMap:(NSDictionary*)map trimWhitespace:(BOOL)trimWhitespace;

+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map;
+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map preserveWhitespace:(BOOL)preserveWhitespace;
+ (NSString*) stringWithTemplate:(NSString*)template fromMap:(NSDictionary*)map preserveWhitespace:(BOOL)preserveWhitespace start:(NSString*)start end:(NSString*)end;


@end
