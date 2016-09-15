///
/// Brian Mancini
/// http://derpturkey.com/nsnotificationcenter-with-swift/
/// Provides proxy functionality for NSNotificationCenter
/// events for Swift classes that do not support integration
/// with Objective-C code.
///

@objc class ObserverProxy : NSObject {
    
    var closure: (Notification) -> ();
    var name: String;
    var object: AnyObject?;
    
    init(name: String, closure: @escaping (Notification) -> ()) {
        self.closure = closure;
        self.name = name;
        super.init()
        self.start();
    }
    
    convenience init(name: String, object: AnyObject, closure: @escaping (Notification) -> ()) {
        self.init(name: name, closure: closure);
        self.object = object;
    }
    
    deinit {
        stop()
    }
    
    func start() {
        NotificationCenter.default.addObserver(self, selector:#selector(ObserverProxy.handler(_:)), name:NSNotification.Name(rawValue: name), object: object);
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self);
    }
    
    func handler(_ notification: Notification) {
        closure(notification);
    }
}
