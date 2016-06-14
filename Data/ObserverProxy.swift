///
/// Brian Mancini
/// http://derpturkey.com/nsnotificationcenter-with-swift/
/// Provides proxy functionality for NSNotificationCenter
/// events for Swift classes that do not support integration
/// with Objective-C code.
///

@objc class ObserverProxy : NSObject {
    
    var closure: (NSNotification) -> ();
    var name: String;
    var object: AnyObject?;
    
    init(name: String, closure: (NSNotification) -> ()) {
        self.closure = closure;
        self.name = name;
        super.init()
        self.start();
    }
    
    convenience init(name: String, object: AnyObject, closure: (NSNotification) -> ()) {
        self.init(name: name, closure: closure);
        self.object = object;
    }
    
    deinit {
        stop()
    }
    
    func start() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ObserverProxy.handler(_:)), name:name, object: object);
    }
    
    func stop() {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    func handler(notification: NSNotification) {
        closure(notification);
    }
}