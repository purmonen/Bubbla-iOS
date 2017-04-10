import Foundation

public enum Response<T> {
    case success(T)
    case error(Error)
    
    func map<G>(_ transform: (T) -> G) -> Response<G> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .error(let error):
            return .error(error)
        }
    }
    
    static func flatten<T>(_ response: Response<Response<T>>) -> Response<T> {
        switch response {
        case .success(let innerResponse):
            return innerResponse
        case .error(let error):
            return .error(error)
        }
    }
    
    func flatMap<G>(_ transform: (T) -> Response<G>) -> Response<G> {
        return Response.flatten(map(transform))
    }
}

infix operator >>= {}
func >>=<T, G>(response: Response<T>, transform: (T) -> Response<G>) -> Response<G> {
    return response.flatMap(transform)
}
