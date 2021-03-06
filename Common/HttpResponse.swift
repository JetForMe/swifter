//
//  HttpResponse.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum HttpResponseBody {
    
    case JSON(AnyObject)
    case XML(AnyObject)
    case PLIST(AnyObject)
    case HTML(String)
    case RAW(String)
    
    func data() -> (content: String?, contentType: String?) {
        switch self {
        case .JSON(let object):
            if NSJSONSerialization.isValidJSONObject(object) {
                do {
                    let json = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.PrettyPrinted)
                    if let nsString = NSString(data: json, encoding: NSUTF8StringEncoding) {
                        return (nsString as String, "application/json")
                    }
                } catch let serializationError as NSError {
                    return ("Serialisation error: \(serializationError)", nil)
                }
            }
            return ("Invalid object to serialise.", nil)
        case .XML(_):
            return ("XML serialization not supported.", nil)
        case .PLIST(let object):
            let format = NSPropertyListFormat.XMLFormat_v1_0
            if NSPropertyListSerialization.propertyList(object, isValidForFormat: format) {
                do {
                    let plist = try NSPropertyListSerialization.dataWithPropertyList(object, format: format, options: 0)
                    if let nsString = NSString(data: plist, encoding: NSUTF8StringEncoding) {
                        return (nsString as String, "application/plist")
                    }
                } catch let serializationError as NSError {
                    return ("Serialisation error: \(serializationError)", nil)
                }
            }
            return ("Invalid object to serialise.", nil)
        case .RAW(let body):
            return (body, "application/octet-stream")
        case .HTML(let body):
            return ("<html><body>\(body)</body></html>", "text/html")
        }
    }
}

public enum HttpResponse {
    
    case OK(HttpResponseBody), Created, Accepted
    case MovedPermanently(String)
    case BadRequest, Unauthorized, Forbidden, NotFound
    case InternalServerError
    case RAW(Int, NSData)
    
    func statusCode() -> Int {
        switch self {
        case .OK(_)                 : return 200
        case .Created               : return 201
        case .Accepted              : return 202
        case .MovedPermanently      : return 301
        case .BadRequest            : return 400
        case .Unauthorized          : return 401
        case .Forbidden             : return 403
        case .NotFound              : return 404
        case .InternalServerError   : return 500
        case .RAW(let code, _)      : return code
        }
    }
    
    func reasonPhrase() -> String {
        switch self {
        case .OK(_)                 : return "OK"
        case .Created               : return "Created"
        case .Accepted              : return "Accepted"
        case .MovedPermanently      : return "Moved Permanently"
        case .BadRequest            : return "Bad Request"
        case .Unauthorized          : return "Unauthorized"
        case .Forbidden             : return "Forbidden"
        case .NotFound              : return "Not Found"
        case .InternalServerError   : return "Internal Server Error"
        case .RAW(_,_)              : return "Custom"
        }
    }
    
    func headers() -> [String: String] {
        var headers = [String:String]()
        headers["Server"] = "Swifter"
        switch self {
		case .OK(let body):
			let d = body.data()
			if let ct = d.1
			{
				headers["Content-Type"] = ct
			}
			
        case .MovedPermanently(let location) : headers["Location"] = location
        default:[]
        }
        return headers
    }
    
    func body() -> NSData? {
        switch self {
        case .OK(let body):
			let d = body.data()
			return d.0?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
			
        case .RAW(_, let data)  : return data
        default                 : return nil
        }
    }
}

/**
	Makes it possible to compare handler responses with '==', but
	ignores any associated values. This should generally be what
	you want. E.g.:
	
		let resp = handler(updatedRequest)
		if resp == .NotFound {
			print("Client requested not found: \(request.url)")
		}
*/

func ==(inLeft: HttpResponse, inRight: HttpResponse) -> Bool {
	return inLeft.statusCode() == inRight.statusCode()
}
