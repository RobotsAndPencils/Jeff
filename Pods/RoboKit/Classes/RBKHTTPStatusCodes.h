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

typedef NS_ENUM(NSInteger, RBKHTTPStatus) {
    // Informational - 1xx codes
    RBKHTTPStatus100Continue = 100,
    RBKHTTPStatus101SwitchingProtocols = 101,

    // Successful - 2xx codes
    RBKHTTPStatus200OK = 200,
    RBKHTTPStatus201Created = 201,
    RBKHTTPStatus202Accepted = 202,
    RBKHTTPStatus203NonAuthoritative = 203,
    RBKHTTPStatus204NoContent = 204,
    RBKHTTPStatus205ResetContent = 205,
    RBKHTTPStatus206PartialContent = 206,

    // Redirection - 3xx codes
    RBKHTTPStatus300MultipleChoices = 300,
    RBKHTTPStatus301MovedPermanently = 301,
    RBKHTTPStatus302Found = 302,
    RBKHTTPStatus303SeeOther = 303,
    RBKHTTPStatus304NotModified = 304,
    RBKHTTPStatus305UseProxy = 305,
    RBKHTTPStatus307TemporaryRedirect = 307,

    // Client errors - 4xx codes
    RBKHTTPStatus400BadRequest = 400,
    RBKHTTPStatus401Unauthorized = 401,
    RBKHTTPStatus402PaymentRequired = 402,
    RBKHTTPStatus403Forbidden = 403,
    RBKHTTPStatus404NotFound = 404,
    RBKHTTPStatus405MethodNotAllowed = 405,
    RBKHTTPStatus406NotAcceptable = 406,
    RBKHTTPStatus407ProxyAuthenticationRequired = 407,
    RBKHTTPStatus408RequestTimeout = 408,
    RBKHTTPStatus409Conflict = 409,
    RBKHTTPStatus410Gone = 410,
    RBKHTTPStatus411LengthRequired = 411,
    RBKHTTPStatus412PreconditionFailed = 412,
    RBKHTTPStatus413RequestEntityTooLarge = 413,
    RBKHTTPStatus414RequestURITooLong = 414,
    RBKHTTPStatus415UnsupportedMediaType = 415,
    RBKHTTPStatus416RequestedRangeNotSatisfiable = 416,
    RBKHTTPStatus417ExpectationFailed = 417,

    // Server errors - 5xx codes
    RBKHTTPStatus500InternalServerError = 500,
    RBKHTTPStatus501NotImplemented = 501,
    RBKHTTPStatus502BadGateway = 502,
    RBKHTTPStatus503ServiceUnavailable = 503,
    RBKHTTPStatus504GatewayTimeout = 504,
    RBKHTTPStatus505HTTPVersionNotSupported = 505,
};

extern NSString *RBKHTTPStatusString(RBKHTTPStatus status);
extern BOOL RBKHTTPStatusIsInformational(RBKHTTPStatus status);
extern BOOL RBKHTTPStatusIsSuccessful(RBKHTTPStatus status);
extern BOOL RBKHTTPStatusIsRedirection(RBKHTTPStatus status);
extern BOOL RBKHTTPStatusIsClientError(RBKHTTPStatus status);
extern BOOL RBKHTTPStatusIsServerError(RBKHTTPStatus status);
