//
//  LXControlDevice.m
//  DLNADemo
//
//  Created by 李鑫 on 2019/11/19.
//  Copyright © 2019 李鑫. All rights reserved.
//

#import "LXControlDevice.h"
#import <GDataXMLNode2/GDataXMLNode.h>
#import "LXUPnPDevice.h"
#import "LXUPnPStatusInfo.h"

#define LXDLNA_DIDL @"<?xml version=\"1.0\"?><DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:dlna=\"urn:schemas-dlna-org:metadata-1-0/\"><item id=\"f-0\" parentID=\"0\" restricted=\"0\"><dc:title>Video</dc:title><upnp:artist>unknow</upnp:artist><upnp:class>LXControlDevice</upnp:class><res protocolInfo=\"http-get:*:*/*:*\">%@</res></item></DIDL-Lite>"
#define LXDLNA_DIDL_NO_RES @"<?xml version=\"1.0\" ?><DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:dlna=\"urn:schemas-dlna-org:metadata-1-0/\"><item id=\"f-0\" parentID=\"0\" restricted=\"0\"><dc:title>Video</dc:title><upnp:artist>unknow</upnp:artist><upnp:class>LXControlDevice</upnp:class></item></DIDL-Lite>"

typedef struct {
    unsigned int isExistSetAVTransportURLReponseDelegate:1;
    unsigned int isExistGetTransportInfoResponseDelegate:1;
    unsigned int isExistPlayResponseDelegate:1;
    unsigned int isExistPauseResponseDelegate:1;
    unsigned int isExistStopResponseDelegate:1;
    unsigned int isExistSeekResponseDelegate:1;
    unsigned int isExistPreviousResponseDelegate:1;
    unsigned int isExistNextResponseDelegate:1;
    unsigned int isExistSetVolumeResponseDelegate:1;
    unsigned int isExistGetVolumeResponseDelegate:1;
    unsigned int isExistGetPositionInfoResponseDelegate:1;
    unsigned int isExistSetNextAVTransportURLResponseDelegate:1;
    unsigned int isExistUndefinedResponseDelegate:1;
} LXControlDeviceDelegateFlags;

static NSString *LXControlDevice_Action_SetAVTransportURI = @"SetAVTransportURI";
static NSString *LXControlDevice_Action_SetNextAVTransportURI = @"SetNextAVTransportURI";
static NSString *LXControlDevice_Action_Play = @"Play";
static NSString *LXControlDevice_Action_Pause = @"Pause";
static NSString *LXControlDevice_Action_Stop = @"Stop";
static NSString *LXControlDevice_Action_Next = @"Next";
static NSString *LXControlDevice_Action_Previous = @"Previous";
static NSString *LXControlDevice_Action_GetPositionInfo = @"GetPositionInfo";
static NSString *LXControlDevice_Action_GetTransportInfo = @"GetTransportInfo";
static NSString *LXControlDevice_Action_Seek = @"Seek";
static NSString *LXControlDevice_Action_GetVolume = @"GetVolume";
static NSString *LXControlDevice_Action_SetVolume = @"SetVolume";

@interface LXControlDevice() {
    void (^_getVolumeCompleteBlock)(int volume);
    void (^_getPositionInfoCompleteBlock)(LXUPnPAVPositionInfo *info);
}

@property (nonatomic, assign) LXControlDeviceDelegateFlags delegateFlags;
@property (nonatomic, assign) int localVolume;

@end

@implementation LXControlDevice

- (instancetype)init {
    self = [super init];
    self.localVolume = -1;
    return self;
}

- (instancetype)initWithDevice:(LXUPnPDevice *)device {
    self = [super init];
    self.device = device;
    self.localVolume = -1;
    return self;
}

- (void)setDelegate:(id<LXControlDeviceDelegate>)delegate {
    _delegate = delegate;
    if (_delegate) {
        _delegateFlags.isExistSetAVTransportURLReponseDelegate = [_delegate respondsToSelector:@selector(lx_setAVTransportURLReponse)];
        _delegateFlags.isExistGetTransportInfoResponseDelegate = [_delegate respondsToSelector:@selector(lx_getTransportInfoResponse:)];
        _delegateFlags.isExistPlayResponseDelegate = [_delegate respondsToSelector:@selector(lx_playResponse)];
        _delegateFlags.isExistPauseResponseDelegate = [_delegate respondsToSelector:@selector(lx_pauseResponse)];
        _delegateFlags.isExistStopResponseDelegate = [_delegate respondsToSelector:@selector(lx_stopResponse)];
        _delegateFlags.isExistSeekResponseDelegate = [_delegate respondsToSelector:@selector(lx_seekResponse)];
        _delegateFlags.isExistPreviousResponseDelegate = [_delegate respondsToSelector:@selector(lx_previousResponse)];
        _delegateFlags.isExistNextResponseDelegate = [_delegate respondsToSelector:@selector(lx_nextResponse)];
        _delegateFlags.isExistSetVolumeResponseDelegate = [_delegate respondsToSelector:@selector(lx_setVolumeResponse)];
        _delegateFlags.isExistGetVolumeResponseDelegate = [_delegate respondsToSelector:@selector(lx_getVolumeResponse:)];
        _delegateFlags.isExistGetPositionInfoResponseDelegate = [_delegate respondsToSelector:@selector(lx_getPositionInfoResponse:)];
        _delegateFlags.isExistSetNextAVTransportURLResponseDelegate = [_delegate respondsToSelector:@selector(lx_setNextAVTransportURLResponse)];
        _delegateFlags.isExistUndefinedResponseDelegate = [_delegate respondsToSelector:@selector(lx_undefinedResponse:)];
    } else {
        _delegateFlags.isExistSetAVTransportURLReponseDelegate = 0;
        _delegateFlags.isExistGetTransportInfoResponseDelegate = 0;
        _delegateFlags.isExistPlayResponseDelegate = 0;
        _delegateFlags.isExistPauseResponseDelegate = 0;
        _delegateFlags.isExistStopResponseDelegate = 0;
        _delegateFlags.isExistSeekResponseDelegate = 0;
        _delegateFlags.isExistPreviousResponseDelegate = 0;
        _delegateFlags.isExistNextResponseDelegate = 0;
        _delegateFlags.isExistSetVolumeResponseDelegate = 0;
        _delegateFlags.isExistGetVolumeResponseDelegate = 0;
        _delegateFlags.isExistGetPositionInfoResponseDelegate = 0;
        _delegateFlags.isExistSetNextAVTransportURLResponseDelegate = 0;
        _delegateFlags.isExistUndefinedResponseDelegate = 0;
    }
}

#pragma mark AVTransport
- (void)setAVTransportURL:(NSString *)url {
    if (LXDLNA_kStringIsEmpty(url)) return;
    
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_SetAVTransportURI];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"CurrentURI" stringValue:url]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"CurrentURIMetaData" stringValue:[NSString stringWithFormat:LXDLNA_DIDL, url]]];
    [self _postAction:LXControlDevice_Action_SetAVTransportURI body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport url:url];
}

- (void)_setAVTransportURLwithNoResDIDL:(NSString *)url {
    if (LXDLNA_kStringIsEmpty(url)) return;
    
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_SetAVTransportURI];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"CurrentURI" stringValue:url]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"CurrentURIMetaData" stringValue:LXDLNA_DIDL_NO_RES]];
    [self _postAction:LXControlDevice_Action_SetAVTransportURI body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)setNextAVTransportURL:(NSString *)nextUrl {
    if (LXDLNA_kStringIsEmpty(nextUrl)) return;
    
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_SetNextAVTransportURI];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"NextURI" stringValue:nextUrl]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"NextURIMetaData" stringValue:[NSString stringWithFormat:LXDLNA_DIDL, nextUrl]]];
    [self _postAction:LXControlDevice_Action_SetNextAVTransportURI body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)play {
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_Play];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"Speed" stringValue:@"1"]];
    [self _postAction:LXControlDevice_Action_Play body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)pause {
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_Pause];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [self _postAction:LXControlDevice_Action_Pause body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)stop {
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_Stop];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [self _postAction:LXControlDevice_Action_Stop body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)next {
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_Next];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [self _postAction:LXControlDevice_Action_Next body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)previous {
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_Previous];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [self _postAction:LXControlDevice_Action_Previous body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)seekToTime:(float)time {
    if (time < 0) time = 0;
    [self seekToTartget:[self _getDurationTime:time] unit:LXControlDevice_Unit_REL_TIME];
}

- (void)seekToTimeIncre:(float)increTime {
    __weak typeof(self) weakSelf = self;
    [self getPositionInfo:^(LXUPnPAVPositionInfo *info) {
        [weakSelf seekToTime:info.relTime + increTime];
    }];
}

- (void)seekToTartget:(NSString *)target unit:(NSString *)unit {
    if (![LXControlDevice_Unit_REL_TIME isEqualToString:unit] && ![LXControlDevice_Unit_TRACK_NR isEqualToString:unit]) return;
    
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_Seek];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"Target" stringValue:target]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"Unit" stringValue:unit]];
    [self _postAction:LXControlDevice_Action_Seek body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)getTransportInfo {
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_GetTransportInfo];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [self _postAction:LXControlDevice_Action_GetTransportInfo body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}

- (void)getPositionInfo {
    [self getPositionInfo:nil];
}

- (void)getPositionInfo:(void (^)(LXUPnPAVPositionInfo *info))complete {
    if (complete) _getPositionInfoCompleteBlock = complete;
    
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_GetPositionInfo];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [self _postAction:LXControlDevice_Action_GetPositionInfo body:XMLElement serviceType:LXUPnPDevice_ServiceType_AVTransport];
}


#pragma mark RenderingControl
- (void)setVolume:(int)volume {
    if (volume < 0) volume = 0;
    if (volume > 100) volume = 100;
    
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_SetVolume];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"Channel" stringValue:@"Master"]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"DesiredVolume" stringValue:[NSString stringWithFormat:@"%d", volume]]];
    [self _postAction:LXControlDevice_Action_SetVolume body:XMLElement serviceType:LXUPnPDevice_ServiceType_RenderingControl];
}

- (void)setVolumeIncre:(int)volumeIncre {
    __weak typeof(self) weakSelf = self;
    [self getVolume:^(int volume) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (volume == 100) {
                weakSelf.localVolume = 20;
            }
        });
        if (weakSelf.localVolume != -1) volume = weakSelf.localVolume;
        [weakSelf setVolume:volume + volumeIncre];
        weakSelf.localVolume = volume + volumeIncre;
        
        if (weakSelf.localVolume <= 0) weakSelf.localVolume = 0;
        if (weakSelf.localVolume >= 100) weakSelf.localVolume = 100;
    }];
}

- (void)getVolume {
    [self getVolume:nil];
}

- (void)getVolume:(void (^)(int volume))complete {
    if (complete) _getVolumeCompleteBlock = complete;
    
    NSString *name = [NSString stringWithFormat:@"u:%@", LXControlDevice_Action_GetVolume];
    GDataXMLElement *XMLElement = [GDataXMLElement elementWithName:name];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"InstanceID" stringValue:@"0"]];
    [XMLElement addChild:[GDataXMLElement elementWithName:@"Channel" stringValue:@"Master"]];
    [self _postAction:LXControlDevice_Action_GetVolume body:XMLElement serviceType:LXUPnPDevice_ServiceType_RenderingControl];
}

#pragma mark - post response
- (void)_postResponse:(NSData *)data action:(NSString *)action url:(NSString *)url {
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:data options:0 error:nil];
    GDataXMLElement *xmlEle = [xmlDoc rootElement];
    NSArray *bigArray = [xmlEle children];
    for (int i = 0; i < [bigArray count]; i++) {
        GDataXMLElement *element = [bigArray objectAtIndex:i];
        NSArray *needArr = [element children];
        if ([[element name] hasSuffix:@"Body"]) {
            for (int i = 0; i < needArr.count; i++) {
                GDataXMLElement *ele = [needArr objectAtIndex:i];
                if ([[ele name] hasSuffix:@"SetAVTransportURIResponse"]) {
                    if (self.delegateFlags.isExistSetAVTransportURLReponseDelegate) {
                        [self.delegate lx_setAVTransportURLReponse];
                    }
                    [self getTransportInfo];
                    [self getPositionInfo];
                } else if ([[ele name] hasSuffix:@"SetNextAVTransportURIResponse"]) {
                    if (self.delegateFlags.isExistSetNextAVTransportURLResponseDelegate) {
                        [self.delegate lx_setNextAVTransportURLResponse];
                    }
                } else if ([[ele name] hasSuffix:@"PlayResponse"]) {
                    if (self.delegateFlags.isExistPlayResponseDelegate) {
                        [self.delegate lx_playResponse];
                    }
                } else if ([[ele name] hasSuffix:@"PauseResponse"]) {
                    if (self.delegateFlags.isExistPauseResponseDelegate) {
                        [self.delegate lx_pauseResponse];
                    }
                } else if ([[ele name] hasSuffix:@"StopResponse"]){
                    if (self.delegateFlags.isExistStopResponseDelegate) {
                        [self.delegate lx_stopResponse];
                    }
                } else if ([[ele name] hasSuffix:@"SeekResponse"]) {
                    if (self.delegateFlags.isExistSeekResponseDelegate) {
                        [self.delegate lx_seekResponse];
                    }
                } else if ([[ele name] hasSuffix:@"NextResponse"]) {
                    if (self.delegateFlags.isExistNextResponseDelegate) {
                        [self.delegate lx_nextResponse];
                    }
                } else if ([[ele name] hasSuffix:@"PreviousResponse"]) {
                    if (self.delegateFlags.isExistPreviousResponseDelegate) {
                        [self.delegate lx_previousResponse];
                    }
                } else if ([[ele name] hasSuffix:@"SetVolumeResponse"]) {
                    if (self.delegateFlags.isExistSetVolumeResponseDelegate) {
                        [self.delegate lx_setVolumeResponse];
                    }
                } else if ([[ele name] hasSuffix:@"GetVolumeResponse"]) {
                    if (self.delegateFlags.isExistGetVolumeResponseDelegate) {
                        for (int j = 0; j < [ele children].count; j++) {
                            GDataXMLElement *eleXml = [[ele children] objectAtIndex:j];
                            if ([[eleXml name] isEqualToString:@"CurrentVolume"]) {
                                [self.delegate lx_getVolumeResponse:[eleXml stringValue]];
                            }
                        }
                    }
                    if (_getVolumeCompleteBlock) {
                        for (int j = 0; j < [ele children].count; j++) {
                            GDataXMLElement *eleXml = [[ele children] objectAtIndex:j];
                            if ([[eleXml name] isEqualToString:@"CurrentVolume"]) {
                                self->_getVolumeCompleteBlock([eleXml stringValue].intValue);
                            }
                        }
                    }
                } else if ([[ele name] hasSuffix:@"GetPositionInfoResponse"]) {
                    if (self.delegateFlags.isExistGetPositionInfoResponseDelegate) {
                        LXUPnPAVPositionInfo *info = [[LXUPnPAVPositionInfo alloc] init];
                        [info setArray:[ele children]];
                        [self.delegate lx_getPositionInfoResponse:info];
                    }
                    if (_getPositionInfoCompleteBlock) {
                        LXUPnPAVPositionInfo *info = [[LXUPnPAVPositionInfo alloc] init];
                        [info setArray:[ele children]];
                        self->_getPositionInfoCompleteBlock(info);
                    }
                } else if ([[ele name] hasSuffix:@"GetTransportInfoResponse"]) {
                    if (self.delegateFlags.isExistGetTransportInfoResponseDelegate) {
                        LXUPnPTransportInfo *info = [[LXUPnPTransportInfo alloc] init];
                        [info setArray:[ele children]];
                        [self.delegate lx_getTransportInfoResponse:info];
                    }
                } else {
                    if ([[ele name] hasSuffix:@"Fault"]) {
                        /// 修复三星电视不能设置成功设置URI的情况
                       if ([action isEqualToString:LXControlDevice_Action_SetAVTransportURI] || [action isEqualToString:LXControlDevice_Action_SetNextAVTransportURI]) {
                           if (!LXDLNA_kStringIsEmpty(url)) {
                               [self _setAVTransportURLwithNoResDIDL:url];
                               return;
                           }
                       }
                    }
                    if (self.delegateFlags.isExistUndefinedResponseDelegate) {
                        [self.delegate lx_undefinedResponse:[ele XMLString]];
                    }
                }
            }
        } else {
            if (self.delegateFlags.isExistUndefinedResponseDelegate) {
                [self.delegate lx_undefinedResponse:[xmlEle XMLString]];
            }
        }
    }
}

#pragma mark - post data
- (void)_postAction:(NSString *)action body:(GDataXMLElement *)xmlBody serviceType:(NSString *)serviceType {
    [self _postAction:action body:xmlBody serviceType:serviceType url:nil];
}

- (void)_postAction:(NSString *)action body:(GDataXMLElement *)xmlBody serviceType:(NSString *)serviceType url:(NSString *)_url {
    NSString *url = [self _getPostURL:serviceType]; if (LXDLNA_kStringIsEmpty(url)) return;
    NSString *postXMLString = [self _getPostXMLString:xmlBody serviceType:serviceType]; if (LXDLNA_kStringIsEmpty(postXMLString)) return;
    NSString *SOAPAction = [self _getSOAPAction:action serviceType:serviceType]; if (LXDLNA_kStringIsEmpty(SOAPAction)) return;
        
    NSURL *URL = [NSURL URLWithString:url];
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    [request addValue:SOAPAction forHTTPHeaderField:@"SOAPAction"];
    request.HTTPBody = [postXMLString dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || data == nil) {
            if (self.delegateFlags.isExistUndefinedResponseDelegate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate lx_undefinedResponse:error.localizedDescription];
                });
            }
            LXDLNA_Log(@"%@", error.localizedDescription);
            return;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _postResponse:data action:action url:_url];
            });
#ifdef DEBUG
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            LXDLNA_Log(@"%@", dataString);
#endif
        }
    }];
    [dataTask resume];
}

- (NSString *)_getPostURL:(NSString *)serviceType {
    if ([serviceType isEqualToString:LXUPnPDevice_ServiceType_AVTransport]) {
        if ([self.device.AVTransport.controlURL hasPrefix:@"/"]) {
            return [NSString stringWithFormat:@"%@%@", self.device.urlHeader, self.device.AVTransport.controlURL];
        }else{
            return [NSString stringWithFormat:@"%@/%@", self.device.urlHeader, self.device.AVTransport.controlURL];
        }
    } else if ([serviceType isEqualToString:LXUPnPDevice_ServiceType_RenderingControl]) {
        if ([self.device.RenderingControl.controlURL hasPrefix:@"/"]) {
            return [NSString stringWithFormat:@"%@%@", self.device.urlHeader, self.device.RenderingControl.controlURL];
        } else {
            return [NSString stringWithFormat:@"%@/%@", self.device.urlHeader, self.device.RenderingControl.controlURL];
        }
    }
    return nil;
}

- (NSString *)_getPostXMLString:(GDataXMLElement *)xmlBody serviceType:(NSString *)serviceType {
    GDataXMLElement *xmlEle = [GDataXMLElement elementWithName:@"s:Envelope"];
    [xmlEle addChild:[GDataXMLElement attributeWithName:@"s:encodingStyle" stringValue:@"http://schemas.xmlsoap.org/soap/encoding/"]];
    [xmlEle addChild:[GDataXMLElement attributeWithName:@"xmlns:s" stringValue:@"http://schemas.xmlsoap.org/soap/envelope/"]];
    [xmlEle addChild:[GDataXMLElement attributeWithName:@"xmlns:u" stringValue:serviceType]];
    GDataXMLElement *command = [GDataXMLElement elementWithName:@"s:Body"];
    [command addChild:xmlBody];
    [xmlEle addChild:command];
    return xmlEle.XMLString;
}

- (NSString *)_getSOAPAction:(NSString *)action serviceType:(NSString *)serviceType {
    if ([serviceType isEqualToString:LXUPnPDevice_ServiceType_AVTransport]) {
        return [NSString stringWithFormat:@"\"%@#%@\"", LXUPnPDevice_ServiceType_AVTransport, action];
    } else if ([serviceType isEqualToString:LXUPnPDevice_ServiceType_RenderingControl]) {
        return [NSString stringWithFormat:@"\"%@#%@\"", LXUPnPDevice_ServiceType_RenderingControl, action];
    }
    return nil;
}

#pragma mark - private method
- (NSString *)_getDurationTime:(float)timeValue {
    return [NSString stringWithFormat:@"%02d:%02d:%02d",
            (int)(timeValue / 3600.0),
            (int)(fmod(timeValue, 3600.0) / 60.0),
            (int)fmod(timeValue, 60.0)];
}

@end
