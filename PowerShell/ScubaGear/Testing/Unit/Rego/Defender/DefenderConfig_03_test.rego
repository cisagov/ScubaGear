package defender_test
import rego.v1
import data.defender
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.DEFENDER.3.1v1
#--
test_Spot_Correct if {
    Output := defender.tests with input.atp_policy_for_o365 as [AtpPolicyForO365]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.3.1v1", Output, PASS, true) == true
}

test_Spot_Incorrect if {
    AtpPolicy := json.patch(AtpPolicyForO365, [{"op": "add", "path": "EnableATPForSPOTeamsODB", "value": false}])
    Output := defender.tests with input.atp_policy_for_o365 as [AtpPolicy]
                            with input.defender_license as true

    TestResult("MS.DEFENDER.3.1v1", Output, FAIL, false) == true
}
#--