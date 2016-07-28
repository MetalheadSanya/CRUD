//
//  NSError.swift
//  shiponTaxi
//
//  Created by Alexander Zalutskiy on 25.04.16.
//  Copyright © 2016 Alexander Zalutskiy. All rights reserved.
//

import Foundation
import Gloss

public enum Error: ErrorType, Decodable {
	case incorrectURI
	case objectDoesNotExist
	case objectAlreadyExist
	case incorrectJsonStruct
	case emptyData
	case server(code: Int, message: String)
	case custom(code: Int, domain: String, message: String)
	
	public init?(json: JSON) {
		guard let code: Int = "code" <~~ json
			else { return nil }
		guard let message: String = "message" <~~ json
			else { return nil }
		
		self = .server(code: code, message: message)
	}
	
	init(error: NSError) {
		self = .custom(code: error.code, domain: error.domain, message: error.localizedDescription)
	}
	
	public var domain: String {
		switch self {
		case .server:
			return defaultConfiguration.serverDomain
		case let .custom(_, domain, _):
			return domain
		default:
			return Error.appDomain
		}
	}
	
	public var code: Int {
		switch self {
		case let .server(code, _):
			return code
		case let .custom(code, _, _):
			return code
		case .incorrectJsonStruct:
			return 1001
		case .emptyData:
			return 1002
		case .incorrectURI:
			return 10000
		case .objectDoesNotExist:
			return 10001
		case .objectAlreadyExist:
			return 10002
		}
	}
	
	public var message: String {
		switch self {
		case let .server(_, message):
			return message
		case let .custom(_, _, message):
			return message
		case .incorrectJsonStruct:
			return "Incorrect JSON structure"
		case .emptyData:
			return "Empty response body from server"
		case .incorrectURI:
			return NSLocalizedString("URI for model is incorrect", comment: "")
		case .objectDoesNotExist:
			return NSLocalizedString("Object does not exist", comment: "")
		case .objectAlreadyExist:
			return NSLocalizedString("Object already exist", comment: "")
		}
	}
	
	private static var appDomain: String {
		if let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier {
			return bundleIdentifier
		} else {
			return "com.alexanderZalutskiy.CRUD"
		}
	}
}