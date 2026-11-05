package securitysuite_test

import rego.v1
import data.securitysuite
import data.utils.key.TestResult
import data.utils.key.PASS

#
# Policy MS.SECURITYSUITE.9.1v1
#--

# Default policy meets all limits
test_OutboundSpamLimits_DefaultPolicy_Correct if {
    Output := securitysuite.tests
        with input.outbound_spam_policies as [CompliantDefaultOutboundSpamPolicy]
        with input.outbound_spam_rules as []

    TestResult("MS.SECURITYSUITE.9.1v1", Output, PASS, true) == true
}

# Default policy does not meet all limits
test_OutboundSpamLimits_DefaultPolicy_Incorrect_V1 if {
    NonCompliantPolicy := json.patch(
        CompliantDefaultOutboundSpamPolicy,
        [{"op": "replace", "path": "RecipientLimitExternalPerHour", "value": 501}]
    )

    Output := securitysuite.tests
        with input.outbound_spam_policies as [NonCompliantPolicy]
        with input.outbound_spam_rules as []

    TestResult(
        "MS.SECURITYSUITE.9.1v1",
        Output,
        "Requirement not met",
        false
    ) == true
}

# Default policy uses an action that does not block the user
test_OutboundSpamLimits_DefaultPolicy_Incorrect_V2 if {
    NonCompliantPolicy := json.patch(
        CompliantDefaultOutboundSpamPolicy,
        [{"op": "replace", "path": "ActionWhenThresholdReached", "value": "AlertOnly"}]
    )

    Output := securitysuite.tests
        with input.outbound_spam_policies as [
            NonCompliantPolicy,
            CompliantCustomOutboundSpamPolicy
        ]
        with input.outbound_spam_rules as [{
            "State": "Enabled",
            "Priority": 0,
            "HostedOutboundSpamFilterPolicy": "Custom Policy"
        }]

    TestResult(
        "MS.SECURITYSUITE.9.1v1",
        Output,
        "Requirement not met",
        false
    ) == true
}

# Default policy does not send a copy of suspicious outbound messages to a recipient
test_OutboundSpamCopy_Disabled if {
    NonCompliantPolicy := json.patch(
        CompliantDefaultOutboundSpamPolicy,
        [
            {"op": "add", "path": "BccSuspiciousOutboundMail", "value": false},
            {"op": "add", "path": "BccSuspiciousOutboundMailTo", "value": []}
        ]
    )

    Output := securitysuite.tests
        with input.outbound_spam_policies as [NonCompliantPolicy]
        with input.outbound_spam_rules as []

    TestResult(
        "MS.SECURITYSUITE.9.1v1",
        Output,
        "Requirement not met",
        false
    ) == true
}


# Enabled custom policy also meets all limits
test_OutboundSpamLimits_CustomPolicy_Correct if {
    Output := securitysuite.tests
        with input.outbound_spam_policies as [
            CompliantDefaultOutboundSpamPolicy,
            CompliantCustomOutboundSpamPolicy
        ]
        with input.outbound_spam_rules as [{
            "State": "Enabled",
            "Priority": 0,
            "HostedOutboundSpamFilterPolicy": "Custom Policy"
        }]

    TestResult("MS.SECURITYSUITE.9.1v1", Output, PASS, true) == true
}

# Enabled custom policy does not meet all limits
test_OutboundSpamLimits_CustomPolicy_Incorrect_V1 if {
    NonCompliantPolicy := json.patch(
        CompliantCustomOutboundSpamPolicy,
        [{"op": "replace", "path": "RecipientLimitInternalPerHour", "value": 1001}]
    )

    Output := securitysuite.tests
        with input.outbound_spam_policies as [
            CompliantDefaultOutboundSpamPolicy,
            NonCompliantPolicy
        ]
        with input.outbound_spam_rules as [{
            "State": "Enabled",
            "Priority": 0,
            "HostedOutboundSpamFilterPolicy": "Custom Policy"
        }]

    TestResult(
        "MS.SECURITYSUITE.9.1v1",
        Output,
        "Requirement not met",
        false
    ) == true
}

# Enabled custom policy uses an action that does not block the user.
test_OutboundSpamLimits_CustomPolicy_Incorrect_V2 if {
    NonCompliantPolicy := json.patch(
        CompliantCustomOutboundSpamPolicy,
        [{"op": "replace", "path": "ActionWhenThresholdReached", "value": "AlertOnly"}]
    )

    Output := securitysuite.tests
        with input.outbound_spam_policies as [
            CompliantDefaultOutboundSpamPolicy,
            NonCompliantPolicy
        ]
        with input.outbound_spam_rules as [{
            "State": "Enabled",
            "Priority": 0,
            "HostedOutboundSpamFilterPolicy": "Custom Policy"
        }]

    TestResult(
        "MS.SECURITYSUITE.9.1v1",
        Output,
        "Requirement not met",
        false
    ) == true
}

#--

#
# Policy MS.SECURITYSUITE.9.2v1
# Outbound spam alert policies
#--

# All required alerts are enabled and have a recipient specified
test_OutboundSpamAlerts_AllCorrect if {
    Output := securitysuite.tests
        with input.protection_alerts as [
            UserRestrictedAlert,
            EmailLimitAlert,
            SuspiciousPatternsAlert
        ]

    TestResult("MS.SECURITYSUITE.9.2v1", Output, PASS, true) == true
}

# All required alerts are not enabled
test_OutboundSpamAlerts_RestrictedSenderAlertDisabled if {
    DisabledAlert := json.patch(
        UserRestrictedAlert,
        [{"op": "replace", "path": "Disabled", "value": true}]
    )

    Output := securitysuite.tests
        with input.protection_alerts as [
            DisabledAlert,
            EmailLimitAlert,
            SuspiciousPatternsAlert
        ]

    ReportDetailString := "Requirement not met, the following alert policies are not compliant: User restricted from sending email"

    TestResult(
        "MS.SECURITYSUITE.9.2v1",
        Output,
        ReportDetailString,
        false
    ) == true
}

# Notifications are disabled for the email sending limit alert.
test_OutboundSpamAlerts_NotificationsDisabled if {
    DisabledNotification := json.patch(
        EmailLimitAlert,
        [{"op": "replace", "path": "NotificationEnabled", "value": false},
        {"op": "replace", "path": "NotifyUser", "value": []}]
    )

    Output := securitysuite.tests
        with input.protection_alerts as [
            UserRestrictedAlert,
            DisabledNotification,
            SuspiciousPatternsAlert
        ]

    ReportDetailString := "Requirement not met, the following alert policies are not compliant: Email sending limit exceeded"

    TestResult(
        "MS.SECURITYSUITE.9.2v1",
        Output,
        ReportDetailString,
        false
    ) == true
}

# A required alert is missing
test_OutboundSpamAlerts_MissingPolicy if {
    Output := securitysuite.tests
        with input.protection_alerts as [
            UserRestrictedAlert,
            EmailLimitAlert
        ]

    ReportDetailString := "Requirement not met, the following alert policies are not compliant: Suspicious email sending patterns detected"

    TestResult(
        "MS.SECURITYSUITE.9.2v1",
        Output,
        ReportDetailString,
        false
    ) == true
}
#--