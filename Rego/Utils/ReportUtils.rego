package report.utils

scubaBaseUrl := "https://github.com/cisagov/ScubaGear/blob/AutoBaselineSync/baselines/"

policyAnchor(PolicyId) := anchor {
    anchor := sprintf("#%v", [replace(lower(PolicyId), ".", "")])
}

policyProduct(PolicyId) := product {
    dotIndexes := indexof_n(PolicyId, ".")
    product := lower(substring(PolicyId, 3, dotIndexes[1]-dotIndexes[0]-1))
}

policyLink(PolicyId) := link {

    link := sprintf("<a href=\"%v%v.md%v\" target=\"_blank\">Sharepoint Secure Configuration Baseline policy</a>", [scubaBaseUrl, policyProduct(PolicyId), policyAnchor(PolicyId)])
}

notCheckedDetails(PolicyId) := details {
    details := sprintf("Not currently checked automatically. See %v for instructions on manual check", [policyLink(PolicyId)])
}
 