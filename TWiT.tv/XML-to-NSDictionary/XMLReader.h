//
//  XMLReader.h
//
//

#import <Foundation/Foundation.h>

@interface XMLReader : NSObject <NSXMLParserDelegate>
{
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
}

+ (NSDictionary*)dictionaryForXMLData:(NSData*)data;
+ (NSDictionary*)dictionaryForXMLString:(NSString*)string;

@end
