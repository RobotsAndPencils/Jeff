//
// Created by Michael Beauregard on 2/27/2014.
// Copyright (c) 2014 Robots and Pencils. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  "RoboKit" is a trademark of Robots and Pencils, Inc. and may not be used to endorse or promote products derived from this software without specific prior written permission.
//
//  Neither the name of the Robots and Pencils, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "RBKHTTPStatusCodes.h"

NSString *RBKHTTPStatusString(RBKHTTPStatus status) {
    switch (status) {
        case RBKHTTPStatus100Continue: return @"Continue";
        case RBKHTTPStatus101SwitchingProtocols: return @"Switching Protocols";
        case RBKHTTPStatus200OK: return @"OK";
        case RBKHTTPStatus201Created: return @"Created";
        case RBKHTTPStatus202Accepted: return @"Accepted";
        case RBKHTTPStatus203NonAuthoritative: return @"Non Authoritative";
        case RBKHTTPStatus204NoContent: return @"No Content";
        case RBKHTTPStatus205ResetContent: return @"Reset Content";
        case RBKHTTPStatus206PartialContent: return @"Partial Content";
        case RBKHTTPStatus300MultipleChoices: return @"Multiple Choices";
        case RBKHTTPStatus301MovedPermanently: return @"Moved Permanently";
        case RBKHTTPStatus302Found: return @"Found";
        case RBKHTTPStatus303SeeOther: return @"See Other";
        case RBKHTTPStatus304NotModified: return @"Not Modified";
        case RBKHTTPStatus305UseProxy: return @"Use Proxy";
        case RBKHTTPStatus307TemporaryRedirect: return @"Temporary Redirect";
        case RBKHTTPStatus400BadRequest: return @"Bad Request";
        case RBKHTTPStatus401Unauthorized: return @"Unauthorized";
        case RBKHTTPStatus402PaymentRequired: return @"PaymentRequired";
        case RBKHTTPStatus403Forbidden: return @"Forbidden";
        case RBKHTTPStatus404NotFound: return @"Not Found";
        case RBKHTTPStatus405MethodNotAllowed: return @"Method Not Allowed";
        case RBKHTTPStatus406NotAcceptable: return @"Not Acceptable";
        case RBKHTTPStatus407ProxyAuthenticationRequired: return @"Proxy Authentication Required";
        case RBKHTTPStatus408RequestTimeout: return @"Request Timeout";
        case RBKHTTPStatus409Conflict: return @"Conflict";
        case RBKHTTPStatus410Gone: return @"Gone";
        case RBKHTTPStatus411LengthRequired: return @"Length Required";
        case RBKHTTPStatus412PreconditionFailed: return @"Precondition Failed";
        case RBKHTTPStatus413RequestEntityTooLarge: return @"Request Entity Too Large";
        case RBKHTTPStatus414RequestURITooLong: return @"Request URI Too Long";
        case RBKHTTPStatus415UnsupportedMediaType: return @"Unsupported Media Type";
        case RBKHTTPStatus416RequestedRangeNotSatisfiable: return @"Requested Range Not Satisfiable";
        case RBKHTTPStatus417ExpectationFailed: return @"Expectation Failed";
        case RBKHTTPStatus500InternalServerError: return @"Internal Server Error";
        case RBKHTTPStatus501NotImplemented: return @"Not Implemented";
        case RBKHTTPStatus502BadGateway: return @"Bad Gateway";
        case RBKHTTPStatus503ServiceUnavailable: return @"Service Unavailable";
        case RBKHTTPStatus504GatewayTimeout: return @"Gateway Timeout";
        case RBKHTTPStatus505HTTPVersionNotSupported: return @"HTTP Version Not Supported";
    }
    return @"Invalid Status Code";
}

BOOL RBKHTTPStatusIsInformational(RBKHTTPStatus status) {
    return status >= 100 && status < 200;
}

BOOL RBKHTTPStatusIsSuccessful(RBKHTTPStatus status) {
    return status >= 200 && status < 300;
}

BOOL RBKHTTPStatusIsRedirection(RBKHTTPStatus status) {
    return status >= 300 && status < 400;
}

BOOL RBKHTTPStatusIsClientError(RBKHTTPStatus status) {
    return status >= 400 && status < 500;
}

BOOL RBKHTTPStatusIsServerError(RBKHTTPStatus status) {
    return status >= 500;
}
