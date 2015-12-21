import Foundation

public enum Response<T> {
    case Success(T)
    case Error(ErrorType)
    
    func map<G>(transform: T -> G) -> Response<G> {
        switch self {
        case .Success(let value):
            return .Success(transform(value))
        case .Error(let error):
            return .Error(error)
        }
    }
    
    static func flatten<T>(response: Response<Response<T>>) -> Response<T> {
        switch response {
        case .Success(let innerResponse):
            return innerResponse
        case .Error(let error):
            return .Error(error)
        }
    }
    
    func flatMap<G>(transform: T -> Response<G>) -> Response<G> {
        return Response.flatten(map(transform))
    }
}

infix operator >>= {}
func >>=<T, G>(response: Response<T>, transform: T -> Response<G>) -> Response<G> {
    return response.flatMap(transform)
}