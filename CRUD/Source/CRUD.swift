//
// Created by Alexander Zalutskiy on 21.07.16.
// Copyright (c) 2016 Alexander Zalutskiy. All rights reserved.
//

import Foundation
import Gloss
import Alamofire
import When

public protocol CRUDModel: Decodable, Encodable {
	static var path: String { get }
	var id: Int? { get }
}

private struct Parameters: Encodable {
	let limit: Int?
	let offset: Int?
	let conditions: [String: AnyObject]?
	let sortedBy: [String]?
	
	init(limit: Int? = nil, offset: Int? = nil,
	     conditions: [String: AnyObject]? = nil, sortedBy: [String]? = nil) {
		self.limit = limit
		self.offset = offset
		self.conditions = conditions
		self.sortedBy = sortedBy
	}
	
	func toJSON() -> Gloss.JSON? {
		var json = jsonify([
				"limit" ~~> limit,
				"offset" ~~> offset,
				"order_by" ~~> sortedBy
		])
		
		if conditions == nil {
			return json
		} else if var json = json {
			json += conditions!
			return json
		} else {
			return conditions
		}
	}
}

struct CRUDConfiguration {
	var baseURL = ""
	var serverDomain = ""
	
	private var url: NSURL? {
		guard let url = NSURL(string: baseURL) else { return nil }
		return url
	}
	
	private func defaultRequestWithPath(
			path: String,
			method: Alamofire.Method = .GET,
			parameters: [String: AnyObject]? = nil,
			encoder: Alamofire.ParameterEncoding = .URL) -> NSMutableURLRequest? {
		
		guard let modelURL = url?.URLByAppendingPathComponent(path) else {
			return nil
		}
		
		let request = NSMutableURLRequest(URL: modelURL)
		
		request.HTTPMethod = method.rawValue
		return encoder.encode(request, parameters: parameters).0
	}
}

var defaultConfiguration: CRUDConfiguration = {
	return CRUDConfiguration()
}()

/// Using the 'find' method, you can retrieve the object corresponding to the
/// specified primary key that matches any supplied options.
///
/// - Parameter id: target id
public func find<T:CRUDModel>(id: Int) -> Promise<T> {
	let promise = Promise<T>()
	
	let path = T.path + "/\(id)"
	
	guard let request = defaultConfiguration.defaultRequestWithPath(path) else {
		promise.reject(Error.incorrectURI); return promise
	}
	
	Alamofire.request(request).responseJSON(completionHandler: objectResponse(
			onSuccess: {
				(obj: T) in
				promise.resolve(obj)
			},
			onError: {
				promise.reject($0)
			}))
	
	return promise
}


/// Using the 'find' method, you can retrieve the objects corresponding to the
/// specified primary keys that matches any supplied options.
///
/// - Parameter ids: target ids
public func find<T:CRUDModel>(ids: [Int]) -> Promise<[T]> {
	return all(conditions: ["id": ids])
}

/// The 'take' method retrieves a record without any implicit ordering.
public func take<T:CRUDModel>() -> Promise<T?> {
	return take(1).then { $0.first }
}

/// The 'take' method retrieves a records without any implicit ordering.
///
/// - Parameter count: number of retrieving records
public func take<T:CRUDModel>(count: Int) -> Promise<[T]> {
	return all(limit: count)
}

/// The 'first' method finds the first record ordered by primary key
/// (default).
///
/// - note: don't use '.asc' and '.desc' suffixes for sorting. For using
/// those suffixes use 'order' method
///
/// - Parameter sorted: the array of keys for sorting. Default: '["id"]'
/// - Parameter conditions: hash for filtering records
public func first<T:CRUDModel>(conditions: [String: AnyObject]? = nil,
                               sortedBy: [String] = ["id"])
				-> Promise<T?> {
	return first(1, conditions: conditions, sortedBy: sortedBy).then { $0.first }
}

/// The 'first' method finds the first records ordered by primary key
/// (default).
///
/// - note: don't use '.asc' and '.desc' suffixes for sorting. For using
/// those suffixes use 'order' method
///
/// - Parameter count: count of records
/// - Parameter conditions: hash for filtering records
/// - Parameter sorted: the array of keys for sorting. Default: '["id"]'
public func first<T:CRUDModel>(count: Int,
                               conditions: [String: AnyObject]? = nil,
                               sortedBy: [String] = ["id"])
				-> Promise<[T]> {
	return all(limit: count, sortedBy: sortedBy.map { $0 + "" + ".asc"},
			conditions: conditions)
}

/// The 'last' method finds the last record ordered by primary key
/// (default).
///
/// - note: don't use '.asc' and '.desc' suffixes for sorting. For using
/// those suffixes use 'order' method
///
/// - Parameter conditions: hash for filtering records
/// - Parameter sorted: the array of keys for sorting. Default: '["id"]'
public func last<T:CRUDModel>(conditions: [String: AnyObject]? = nil,
                              sortedBy: [String] = ["id"])
				-> Promise<T?> {
	return last(1, conditions: conditions, sortedBy: sortedBy).then { $0.first }
}

/// The 'last' method finds the last records ordered by primary key
/// (default).
///
/// - note: don't use '.asc' and '.desc' suffixes for sorting. For using
/// those suffixes use 'order' method
///
/// - Parameter count: count of records
/// - Parameter conditions: hash for filtering records
/// - Parameter sorted: the array of keys for sorting. Default: '["id"]'
public func last<T:CRUDModel>(count: Int,
                              conditions: [String: AnyObject]? = nil,
                              sortedBy: [String] = ["id"]) -> Promise<[T]> {
	return all(limit: count, sortedBy: sortedBy.map { $0 + "" + ".desc"},
			conditions: conditions)
}

/// The 'findBy' method finds the first record matching some conditions.
///
/// - Parameter conditions: find conditions
public func findBy<T:CRUDModel>(conditions: [String: AnyObject])
				-> Promise<T?> {
	return wherein(conditions).then { $0.first }
}

/// The 'wherein' method finds records matching some conditions.
///
/// - Parameter conditions: find conditions
/// - Parameter count: count of record
/// - Parameter offset: offset of first received record
/// - Parameter sortedBy: array of fields name for sorting
public func wherein<T:CRUDModel>(conditions: [String: AnyObject],
                                 count: Int? = nil,
                                 offset: Int? = nil,
                                 sortedBy: [String]? = nil) -> Promise<[T]> {
	return all(limit: count, offset: offset, sortedBy: sortedBy,
			conditions: conditions)
}

/// The 'order' method for retrieve records from the database in a specific
/// order
///
/// - Parameter order: array of fields name for sorting
/// - Parameter count: count of record
/// - Parameter offset: offset of first received record
/// - Parameter conditions: find conditions
public func order<T:CRUDModel>(by order: [String],
                               count: Int? = nil,
                               offset: Int? = nil,
                               conditions: [String: AnyObject]? = nil)
				-> Promise<[T]> {
	return all(limit: count, offset: offset, sortedBy: order,
			conditions: conditions)
}

/// The 'all' method for retrieve all records
///
/// - Parameter order: array of fields name for sorting
/// - Parameter count: count of record
/// - Parameter offset: offset of first received record
/// - Parameter conditions: find conditions
public func all<T:CRUDModel>(limit limit: Int? = nil,
                             offset: Int? = nil,
                             sortedBy: [String]? = nil,
                             conditions: [String: AnyObject]? = nil)
				-> Promise<[T]> {
	let promise = Promise<[T]>()
	
	let parameters = Parameters(limit: limit, offset: offset,
			conditions: conditions, sortedBy: sortedBy)
	
	guard let request = defaultConfiguration.defaultRequestWithPath(
			T.path, parameters: parameters.toJSON()) else {
		promise.reject(Error.incorrectURI); return promise
	}
	
	Alamofire.request(request).responseJSON(completionHandler: objectsResponse(
			onSuccess: {
				(objs: [T]) in
				promise.resolve(objs)
			},
			onError: {
				promise.reject($0)
			}))
	
	return promise
}

public func destroy<T:CRUDModel>(object: T) -> Promise<T?> {
	let promise = Promise<T?>()
	
	let path = T.path + "/\(object.id)"
	
	guard let request = defaultConfiguration.defaultRequestWithPath(
			path, method: .DELETE) else {
		promise.reject(Error.incorrectURI); return promise
	}
	
	Alamofire.request(request).responseJSON(completionHandler: simpleResponse(
			onSuccess: {
				_ in
				promise.resolve(nil)
				return true
			},
			onError: {
				promise.reject($0)
			}))
	
	return promise
}

public func save<T:CRUDModel>(object: T) -> Promise<T> {
	if object.id != nil { return update(object) }
	else { return create(object) }
}

public func update<T:CRUDModel>(object: T) -> Promise<T> {
	let promise = Promise<T>()
	
	guard let id = object.id else {
		promise.reject(Error.objectDoesNotExist); return promise
	}
	
	let path = T.path + "/\(id)"
	
	guard let request = defaultConfiguration.defaultRequestWithPath(
			path,
			method: .PATCH,
			parameters: object.toJSON()) else {
		promise.reject(Error.incorrectURI); return promise
	}
	
	Alamofire.request(request).responseJSON(completionHandler: objectResponse(
			onSuccess: {
				(object: T) in
				promise.resolve(object)
			},
			onError: {
				promise.reject($0)
			}))
	
	return promise
}

public func create<T:CRUDModel>(object: T) -> Promise<T> {
	let promise = Promise<T>()
	
	guard object.id == nil else {
		promise.reject(Error.objectAlreadyExist); return promise
	}
	
	guard let request = defaultConfiguration.defaultRequestWithPath(
			T.path,
			method: .POST,
			parameters: object.toJSON()) else {
		promise.reject(Error.incorrectURI); return promise
	}
	
	Alamofire.request(request).responseJSON(completionHandler: objectResponse(
			onSuccess: {
				(object: T) in
				promise.resolve(object)
			},
			onError: {
				promise.reject($0)
			}))
	
	return promise
}

// MARK: - Alamofire Helper func

private func simpleResponse(
		onSuccess onSuccess: ((AnyObject?) -> Bool),
		onError: ((Error) -> Void)?)
				-> Response<AnyObject, NSError> -> Void {
	return {
		response in
		
		if let error = response.result.error {
			onError?(Error(error: error))
			return
		}
		
		let data = response.result.value!
		if let json = data as? [JSON] {
			
			let errors = [Error].fromJSONArray(json)
			if errors.count != 0  {
				onError?(errors[0])
				return
			}
		}
		
		if !onSuccess(data) {
			onError?(.uncorrectJsonStruct)
		}
	}
}

private func objectResponse<T: Decodable>(
		onSuccess onSuccess: ((T) -> Void)?,
		onError: ((Error) -> Void)?)
				-> Response<AnyObject, NSError> -> Void {
	return simpleResponse(
			onSuccess: {
				data in
				
				guard let json = data as? JSON else { return false }
				guard let obj = T(json: json) else { return false }
				
				onSuccess?(obj)
				
				return true
			}, onError: onError)
}


private func objectsResponse<T: Decodable>(
		onSuccess onSuccess: (([T]) -> Void)?,
		onError: ((Error) -> Void)?)
				-> Response<AnyObject, NSError> -> Void {
	return simpleResponse(
			onSuccess: {
				data in
				
				guard let json = data as? [JSON] else { return false }
				let obj = [T].fromJSONArray(json)
				
				onSuccess?(obj)
				
				return true
			}, onError: onError)
}

private func += <K, V> (inout left: [K:V], right: [K:V]) {
	for (k, v) in right {
		left.updateValue(v, forKey: k)
	}
}