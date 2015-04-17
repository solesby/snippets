//
//  SimpleTemplate.h
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
