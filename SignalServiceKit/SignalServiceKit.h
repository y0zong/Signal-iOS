//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

#import <Foundation/Foundation.h>

//! Project version number for SignalServiceKit.
FOUNDATION_EXPORT double SignalServiceKitVersionNumber;

//! Project version string for SignalServiceKit.
FOUNDATION_EXPORT const unsigned char SignalServiceKitVersionString[];

#import <SignalServiceKit/AppReadiness.h>
#import <SignalServiceKit/BaseModel.h>
#import <SignalServiceKit/DarwinNotificationCenter.h>
#import <SignalServiceKit/DebuggerUtils.h>
#import <SignalServiceKit/FunctionalUtil.h>
#import <SignalServiceKit/IncomingGroupsV2MessageJob.h>
#import <SignalServiceKit/InstalledSticker.h>
#import <SignalServiceKit/KnownStickerPack.h>
#import <SignalServiceKit/LegacyChainKey.h>
#import <SignalServiceKit/LegacyMessageKeys.h>
#import <SignalServiceKit/LegacyReceivingChain.h>
#import <SignalServiceKit/LegacyRootKey.h>
#import <SignalServiceKit/LegacySendingChain.h>
#import <SignalServiceKit/LegacySessionRecord.h>
#import <SignalServiceKit/LegacySessionState.h>
#import <SignalServiceKit/NSData+OWS.h>
#import <SignalServiceKit/NSDate+OWS.h>
#import <SignalServiceKit/NSObject+OWS.h>
#import <SignalServiceKit/NSString+OWS.h>
#import <SignalServiceKit/OWS2FAManager.h>
#import <SignalServiceKit/OWSAddToContactsOfferMessage.h>
#import <SignalServiceKit/OWSAddToProfileWhitelistOfferMessage.h>
#import <SignalServiceKit/OWSArchivedPaymentMessage.h>
#import <SignalServiceKit/OWSAsserts.h>
#import <SignalServiceKit/OWSBlockedPhoneNumbersMessage.h>
#import <SignalServiceKit/OWSDisappearingConfigurationUpdateInfoMessage.h>
#import <SignalServiceKit/OWSDisappearingMessagesConfiguration.h>
#import <SignalServiceKit/OWSDisappearingMessagesConfigurationMessage.h>
#import <SignalServiceKit/OWSDisappearingMessagesJob.h>
#import <SignalServiceKit/OWSDynamicOutgoingMessage.h>
#import <SignalServiceKit/OWSEndSessionMessage.h>
#import <SignalServiceKit/OWSError.h>
#import <SignalServiceKit/OWSGroupCallMessage.h>
#import <SignalServiceKit/OWSHTTPSecurityPolicy.h>
#import <SignalServiceKit/OWSIdentity.h>
#import <SignalServiceKit/OWSIncomingArchivedPaymentMessage.h>
#import <SignalServiceKit/OWSIncomingPaymentMessage.h>
#import <SignalServiceKit/OWSLinkedDeviceReadReceipt.h>
#import <SignalServiceKit/OWSLogs.h>
#import <SignalServiceKit/OWSMessageContentJob.h>
#import <SignalServiceKit/OWSOutgoingArchivedPaymentMessage.h>
#import <SignalServiceKit/OWSOutgoingCallMessage.h>
#import <SignalServiceKit/OWSOutgoingNullMessage.h>
#import <SignalServiceKit/OWSOutgoingPaymentMessage.h>
#import <SignalServiceKit/OWSOutgoingReactionMessage.h>
#import <SignalServiceKit/OWSOutgoingResendRequest.h>
#import <SignalServiceKit/OWSOutgoingSenderKeyDistributionMessage.h>
#import <SignalServiceKit/OWSOutgoingSentMessageTranscript.h>
#import <SignalServiceKit/OWSOutgoingSyncMessage.h>
#import <SignalServiceKit/OWSPaymentActivationRequestFinishedMessage.h>
#import <SignalServiceKit/OWSPaymentActivationRequestMessage.h>
#import <SignalServiceKit/OWSPaymentMessage.h>
#import <SignalServiceKit/OWSProfileKeyMessage.h>
#import <SignalServiceKit/OWSReadReceiptsForLinkedDevicesMessage.h>
#import <SignalServiceKit/OWSReadTracking.h>
#import <SignalServiceKit/OWSReceiptManager.h>
#import <SignalServiceKit/OWSReceiptsForSenderMessage.h>
#import <SignalServiceKit/OWSRecipientIdentity.h>
#import <SignalServiceKit/OWSRecoverableDecryptionPlaceholder.h>
#import <SignalServiceKit/OWSStaticOutgoingMessage.h>
#import <SignalServiceKit/OWSStickerPackSyncMessage.h>
#import <SignalServiceKit/OWSSyncConfigurationMessage.h>
#import <SignalServiceKit/OWSSyncFetchLatestMessage.h>
#import <SignalServiceKit/OWSSyncKeysMessage.h>
#import <SignalServiceKit/OWSSyncMessageRequestResponseMessage.h>
#import <SignalServiceKit/OWSSyncRequestMessage.h>
#import <SignalServiceKit/OWSUnknownContactBlockOfferMessage.h>
#import <SignalServiceKit/OWSUnknownProtocolVersionMessage.h>
#import <SignalServiceKit/OWSVerificationStateChangeMessage.h>
#import <SignalServiceKit/OWSVerificationStateSyncMessage.h>
#import <SignalServiceKit/OWSViewOnceMessageReadSyncMessage.h>
#import <SignalServiceKit/OWSViewedReceiptsForLinkedDevicesMessage.h>
#import <SignalServiceKit/OutgoingPaymentSyncMessage.h>
#import <SignalServiceKit/PreKeyRecord.h>
#import <SignalServiceKit/ProfileManagerProtocol.h>
#import <SignalServiceKit/ProtoUtils.h>
#import <SignalServiceKit/SDSCrossProcess.h>
#import <SignalServiceKit/SDSDatabaseStorage+Objc.h>
#import <SignalServiceKit/SDSKeyValueStore+ObjC.h>
#import <SignalServiceKit/SSKAccessors+SDS.h>
#import <SignalServiceKit/SSKAsserts.h>
#import <SignalServiceKit/SSKPreKeyStore.h>
#import <SignalServiceKit/SSKSignedPreKeyStore.h>
#import <SignalServiceKit/SignedPrekeyRecord.h>
#import <SignalServiceKit/StickerInfo.h>
#import <SignalServiceKit/StickerPack.h>
#import <SignalServiceKit/TSAttachment.h>
#import <SignalServiceKit/TSAttachmentPointer.h>
#import <SignalServiceKit/TSAttachmentStream.h>
#import <SignalServiceKit/TSCall.h>
#import <SignalServiceKit/TSContactThread.h>
#import <SignalServiceKit/TSErrorMessage.h>
#import <SignalServiceKit/TSGroupModel.h>
#import <SignalServiceKit/TSGroupThread.h>
#import <SignalServiceKit/TSIncomingMessage.h>
#import <SignalServiceKit/TSInfoMessage.h>
#import <SignalServiceKit/TSInteraction.h>
#import <SignalServiceKit/TSInvalidIdentityKeyErrorMessage.h>
#import <SignalServiceKit/TSInvalidIdentityKeyReceivingErrorMessage.h>
#import <SignalServiceKit/TSInvalidIdentityKeySendingErrorMessage.h>
#import <SignalServiceKit/TSMessage.h>
#import <SignalServiceKit/TSOutgoingDeleteMessage.h>
#import <SignalServiceKit/TSOutgoingMessage.h>
#import <SignalServiceKit/TSPaymentModel.h>
#import <SignalServiceKit/TSPaymentModels.h>
#import <SignalServiceKit/TSPrivateStoryThread.h>
#import <SignalServiceKit/TSQuotedMessage.h>
#import <SignalServiceKit/TSStorageKeys.h>
#import <SignalServiceKit/TSThread.h>
#import <SignalServiceKit/TSUnreadIndicatorInteraction.h>
#import <SignalServiceKit/TSYapDatabaseObject.h>
#import <SignalServiceKit/Threading.h>
#import <SignalServiceKit/YDBStorage.h>

#define OWSLocalizedString(key, comment)                                                                               \
    [[NSBundle mainBundle].appBundle localizedStringForKey:(key) value:@"" table:nil]
