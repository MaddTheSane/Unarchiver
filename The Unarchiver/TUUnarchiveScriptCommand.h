#import "TUController.h"

@interface TUUnarchiveScriptCommand : NSScriptCommand

- (instancetype)initWithCommandDescription:(NSScriptCommandDescription *)commandDef;
- (id)performDefaultImplementation;

- (BOOL)evalBooleanParameterForKey:(NSString *)parameterKey;
- (id)errorFileDontExist:(NSString *)file;

- (void)unarchiveFile:(NSString *)fileName;
- (void)quitIfPossible;

@end
