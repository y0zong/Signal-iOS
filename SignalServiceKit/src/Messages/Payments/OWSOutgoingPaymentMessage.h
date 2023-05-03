//
// Copyright 2021 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

#import <SignalServiceKit/TSOutgoingMessage.h>

NS_ASSUME_NONNULL_BEGIN

@class TSPaymentCancellation;
@class TSPaymentNotification;
@class TSPaymentRequest;

@interface OWSOutgoingPaymentMessage : TSOutgoingMessage

@property (nonatomic, readonly, nullable) TSPaymentRequest *paymentRequest;
@property (nonatomic, readonly, nullable) TSPaymentNotification *paymentNotification;
@property (nonatomic, readonly, nullable) TSPaymentCancellation *paymentCancellation;

- (instancetype)initOutgoingMessageWithBuilder:(TSOutgoingMessageBuilder *)outgoingMessageBuilder
                                   transaction:(SDSAnyReadTransaction *)transaction NS_UNAVAILABLE;

- (instancetype)initWithThread:(TSThread *)thread
           paymentCancellation:(nullable TSPaymentCancellation *)paymentCancellation
           paymentNotification:(nullable TSPaymentNotification *)paymentNotification
                paymentRequest:(nullable TSPaymentRequest *)paymentRequest
              expiresInSeconds:(uint32_t)expiresInSeconds
                   transaction:(SDSAnyReadTransaction *)transaction;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                   attachmentIds:(NSArray<NSString *> *)attachmentIds
                            body:(nullable NSString *)body
                      bodyRanges:(nullable MessageBodyRanges *)bodyRanges
                    contactShare:(nullable OWSContact *)contactShare
                       editState:(TSEditState)editState
                 expireStartedAt:(uint64_t)expireStartedAt
                       expiresAt:(uint64_t)expiresAt
                expiresInSeconds:(unsigned int)expiresInSeconds
                       giftBadge:(nullable OWSGiftBadge *)giftBadge
               isGroupStoryReply:(BOOL)isGroupStoryReply
              isViewOnceComplete:(BOOL)isViewOnceComplete
               isViewOnceMessage:(BOOL)isViewOnceMessage
                     linkPreview:(nullable OWSLinkPreview *)linkPreview
                  messageSticker:(nullable MessageSticker *)messageSticker
                   quotedMessage:(nullable TSQuotedMessage *)quotedMessage
    storedShouldStartExpireTimer:(BOOL)storedShouldStartExpireTimer
           storyAuthorUuidString:(nullable NSString *)storyAuthorUuidString
              storyReactionEmoji:(nullable NSString *)storyReactionEmoji
                  storyTimestamp:(nullable NSNumber *)storyTimestamp
              wasRemotelyDeleted:(BOOL)wasRemotelyDeleted
                   customMessage:(nullable NSString *)customMessage
                groupMetaMessage:(TSGroupMetaMessage)groupMetaMessage
           hasLegacyMessageState:(BOOL)hasLegacyMessageState
             hasSyncedTranscript:(BOOL)hasSyncedTranscript
              isFromLinkedDevice:(BOOL)isFromLinkedDevice
                  isVoiceMessage:(BOOL)isVoiceMessage
              legacyMessageState:(TSOutgoingMessageState)legacyMessageState
              legacyWasDelivered:(BOOL)legacyWasDelivered
           mostRecentFailureText:(nullable NSString *)mostRecentFailureText
          recipientAddressStates:(nullable NSDictionary<SignalServiceAddress *,TSOutgoingMessageRecipientState *> *)recipientAddressStates
              storedMessageState:(TSOutgoingMessageState)storedMessageState
             paymentCancellation:(nullable TSPaymentCancellation *)paymentCancellation
             paymentNotification:(nullable TSPaymentNotification *)paymentNotification
                  paymentRequest:(nullable TSPaymentRequest *)paymentRequest
NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(grdbId:uniqueId:receivedAtTimestamp:sortId:timestamp:uniqueThreadId:attachmentIds:body:bodyRanges:contactShare:editState:expireStartedAt:expiresAt:expiresInSeconds:giftBadge:isGroupStoryReply:isViewOnceComplete:isViewOnceMessage:linkPreview:messageSticker:quotedMessage:storedShouldStartExpireTimer:storyAuthorUuidString:storyReactionEmoji:storyTimestamp:wasRemotelyDeleted:customMessage:groupMetaMessage:hasLegacyMessageState:hasSyncedTranscript:isFromLinkedDevice:isVoiceMessage:legacyMessageState:legacyWasDelivered:mostRecentFailureText:recipientAddressStates:storedMessageState:paymentCancellation:paymentNotification:paymentRequest:));

// clang-format on

// --- CODE GENERATION MARKER

@end

NS_ASSUME_NONNULL_END
